#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: SMTP.pm,v 1.31 2004/06/27 02:39:31 fukachan Exp $
#


package Mail::Delivery::SMTP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::Socket;
use Mail::Delivery::Utils;
use Mail::Delivery::Net::INET4;
use Mail::Delivery::Net::INET6;


BEGIN {}
END   {}

# MAP IO STATUS CODE
my $MAP_DONE     = 'DONE';
my $MAP_NOT_DONE = 'NOT DONE';
my $MAP_ERR_OPEN = 'CANNOT OPEN';

# MTA IO STATUS CODE
my $MTA_OK          = 'OK';
my $MTA_ERR_TIMEOUT = 'TIMEOUT';

# SMTP STATUS
my $SMTP_OK         = 'OK';
my $SMTP_ERR_RETRY  = 'SMTP RETRY';


=head1 NAME

Mail::Delivery::SMTP - interface for SMTP service

=head1 SYNOPSIS

To initialize,

    use Mail::Message;

      ... make $message (Mail::Message object) ...

    use Mail::Delivery::SMTP;
    my $fp  = sub { Log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    my $service = new Mail::Delivery::SMTP {
        log_function       => $fp,
        smtp_log_function  => $sfp,
        default_io_timeout => 10,
    };
    if ($service->error) { Log($service->error); return;}

To start delivery, use deliver() method in this way.

    $service->deliver(
                      {
                          smtp_servers    => '[::1]:25 127.0.0.1:25',

                          smtp_sender     => 'rudo@nuinui.net',
                          recipient_maps  => $recipient_maps,
                          recipient_limit => 1000,

                          message         => $message,
                      });

C<message> is a C<Mail::Message> object.
You can specify the recipient list as an ARRAY REFERENCE.

    # reference to an array of recipients
    @array = ( 'kenken@nuinui.net' );

    $service->deliver(
                      {
                          smtp_servers    => '[::1]:25 127.0.0.1:25',

                          smtp_sender     => 'rudo@nuinui.net',
                          recipient_array => \@array,
                          recipient_limit => 1000,

                          message         => $message,
                      });

=head1 DESCRIPTION

This module provides SMTP/ESMTP mail delivery service.
It tries IPv6 connection If possible.

The socket creation and tcp connection is controlled by
sub-classes,
C<Mail::Delivery::Net::INET4> and
C<Mail::Delivery::Net::INET6>.

It sends a list of all recipients indicated by $recipient_maps.
C<IO::Adapter> resolves $recipient_maps and provides the abstract
IO layer. It provides the usual file IO methods for each C<map>.
See L<IO::Adapter> for more details.

=head1 METHODS

=head2 new($args)

the constructor.
Please specify it in a hash reference as an argument of new().
Several parameters on logging and timeout et. al. are avialable.

   hash key             value
   --------------------------------------------
   log_function         reference to function for logging
   smtp_log_function    reference to function for logging
   default_io_timeout   default timeout associated with the socket IO

C<log_function()> is the function pointer to write a message in the
log file.
C<smtp_log_function()> is special function pointer to log SMTP
transactions.

=cut


# Descriptions: Mail::Delivery::SMTP constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: $self ($me) hash has some default values
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {}; # malloc new SMTP session struct

    #     _recipient_limit: maximum recipients in one smtp session.
    #  _default_io_timeout: basic timeout parameter for smtp session
    #        _log_function: pointer to the log() function
    $me->{ _recipient_limit }    = $args->{recipient_limit}    || 1000;
    $me->{ _default_io_timeout } = $args->{default_io_timeout} || 10;
    $me->{ _log_function }       = $args->{log_function}       || undef;
    $me->{ _smtp_log_function }  = $args->{smtp_log_function}  || undef;
    $me->{ _smtp_log_handle }    = $args->{smtp_log_handle}    || undef;
    $me->{ _num_recipients }     = 0;

    # define package global pointer to the log() function
    $LogFunctionPointer     = $args->{log_function}      || undef;
    $SmtpLogFunctionPointer = $args->{smtp_log_function} || undef;

    bless $me, $type;

    _initialize_delivery_session($me, $args);

    return bless $me, $type;
}


# Descriptions: send a (SMTP/LMTP) command string to BSD socket.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update log file by smtplog.
#               set _last_command and _error_action in object itself
# Return Value: none
sub _send_command
{
    my ($self, $command) = @_;
    my $socket = $self->{'_socket'} || undef;

    $self->set_last_command($command);
    $self->set_send_command_status('');
    $self->smtplog($command."\r\n");

    if (defined $socket) {
	$socket->print($command, "\r\n");
    }
    else {
	Log("Error: _send_command: undefined socket");
    }
}


# Descriptions: receive a reply for a (SMTP/LMTP) command.
#    Arguments: OBJ($self)
# Side Effects: update log file by smtplog.
# Return Value: none
sub _read_reply
{
    my ($self) = @_;
    my $socket = $self->{'_socket'};

    # unique identifier to clarify the trapped error message
    my $id = $$;

    # toggle flag whether we should check SMTP attributes or not.
    # we should check it only in HELO phase.
    my $check_attributes = 0;
    my $last_command     = $self->get_last_command();
    if ($last_command =~ /^(EHLO|HELO|LHLO)/o) {
	$check_attributes = 1;
    }

    # XXX Attention! dynamic scope by local() for %SIG is essential.
    #     See books on Perl for more details on my() and local() difference.
    eval {
	local($SIG{ALRM}) = sub { croak("$id socket timeout");};
	alarm( $self->{_default_io_timeout} );
	my $buf = '';

	croak("socket is not connected") unless
	    $self->is_socket_connected($socket);

      SMTP_REPLY:
	while (1) {
	    $buf = $socket->getline;
	    $self->smtplog($buf);

	    # check smtp attributes
	    if ($check_attributes) {
		if ($buf =~ /^250.PIPELINING/i) {
		    $self->{'_can_use_pipelining'} = 'yes';
		}
		if ($buf =~ /^250.ETRN/i) {
		    $self->{'_can_use_etrn'} = 'yes';
		}
		if ($buf =~ /^250.SIZE\s+(\d+)/i) {
		    $self->{'_size_limit'} = $1;
		}
	    }

	    # store the latest status code
	    if ($buf =~ /^(\d{3})/) { $self->set_status_code($1);}

	    # check status code
	    if ($buf =~ /^[45]\d{2}\s/) {
		Log($buf);
		die("$id retry");
	    }

	    # end of reply e.g. "250 ..."
	    last SMTP_REPLY if $buf =~ /^\d{3}\s/;
	}
    };

    if ($@ =~ /$id retry/) {
	$self->set_send_command_status($SMTP_ERR_RETRY);
	Log("need smtp retry");
	$self->error_set("need smtp retry");
    }

    if ($@ =~ /$id socket timeout/) {
	my $x = $self->get_last_command();
	Log("Error: smtp reply for \"$x\" is timeout");
	$self->error_set("Error: smtp reply for \"$x\" is timeout");
    }

    # reset latest alarm() setting
    alarm(0);
}


# Descriptions: save last command info.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update $self
# Return Value: none
sub set_last_command
{
    my ($self, $command) = @_;

    $self->{ _last_command } = $command;
}


# Descriptions: get last command info.
#    Arguments: OBJ($self)
# Side Effects: update $self
# Return Value: none
sub get_last_command
{
    my ($self) = @_;

    return( $self->{ _last_command } || '' );
}


# Descriptions: save send command info.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update $self
# Return Value: none
sub set_send_command_status
{
    my ($self, $command) = @_;

    $self->{ _send_command_status } = $command;
}


# Descriptions: get send command info.
#    Arguments: OBJ($self)
# Side Effects: update $self
# Return Value: none
sub get_send_command_status
{
    my ($self) = @_;

    return( $self->{ _send_command_status } || '' );
}


# Descriptions: connect(2)
#               1. try connect(2) by IPv6 if we can use Socket6.pm
#               2. try connect(2) by IPv4
#                  if $host is not IPv6 raw address e.g. [::1]:25
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: set file handle (BSD socket) in $self->{_socket}
# Return Value: file handle (created BSD socket) or undef()
sub _connect
{
    my ($self, $args) = @_;
    my $mta = $args->{'_mta'} || '127.0.0.1:25';
    my $socket;

    $self->error_clear;

    # 1. try to connect(2) $args->{ _mta } by IPv6 if we can use Socket6.
    if ($self->is_ipv6_ready($args)) {
	Log("debug: try mta=$args->{_mta} by IPv6");
	$self->connect6($args);
	my $socket = $self->{_socket};
	return $socket if defined $socket;
    }
    else {
	Log("IPv6 is not ready");
    }

    $self->error_clear;

    # 2. try to connect(2) $args->{ _mta } by IPv4.
    #    XXX check the _mta syntax.
    #    XXX if $args->{ _mta } looks [$ipv6_addr]:$port style,
    #    XXX we do not try to connect the host by IPv4.
    if ( $self->is_ipv6_mta_syntax($mta) ) {
	Log("debug: not try MTA $args->{_mta}");
	return undef;
    }
    else {
	Log("debug: try mta=$args->{_mta} by IPv4");
	return $self->connect4($args);
    }
}


=head2 is_socket_connected($socket)

$socket has peer or not by C<getpeername()>.

   XXX sub $socket->connected { getpeername($self);}
   XXX IO::Socket of old perl have no such method.

=cut


# Descriptions: this socket is connected or not.
#    Arguments: OBJ($self) HANDLE($socket)
# Side Effects: none
# Return Value: 1 or 0
sub is_socket_connected
{
    my ($self, $socket) = @_;

    if (defined $socket) {
	return( getpeername($socket) );
    }

    return 0;
}


=head2 close()

close BSD socket

=cut

# Descriptions: close BSD socket.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as close()
sub close
{
    my ($self) = @_;
    my $socket = $self->{'_socket'};

    if (defined $socket) {
	$socket->close;
    }
    else {
	Log("Error: try to close invalid socket");
    }
}


############################################################
#####
##### SMTP delivery main loop
#####

=head2 deliver($args)

start delivery process.
You can specify the following parameter at C<$args> HASH REFERENCE.

    hash key           value
    --------------------------------------------
    smtp_servers       127.0.0.1:25 [::1]:25
    smtp_sender        sender's mail address
    recipient_maps     $recipient_maps
    recipient_limit    recipients in one SMTP transactions
    header             FML::Header object
    body               Mail::Message object

C<smtp_servers> is a list of MTA's (Mail Transport Agents).
The syntax of each MTA is C<host:port> or C<address:port> style.
If you use a raw IPv6 address, use C<[address]:port> syntax.
For example, [::1]:25 (IPv6 loopback address).
You can specify a combination of IPv4 and IPv6 addresses at
C<smtp_servers>.
C<deliver()> automatically tries smtp connection on both protocols.

C<smtp_sender> is the sender's email address.
It is used at MAIL FROM: command.

C<recipient_maps> is a list of C<maps>.
See L<IO::Adapter> for more details.
For example,

To read addresses from a file, specify the map as

         file:/var/spool/ml/elena/recipients

and to read addresses from /etc/group

         unix.group:fml

C<recipient_limit> is the max number of recipients in one SMTP
transaction. 1000 by default,
which corresponds to the limit by C<Postfix>.

C<header> is an C<FML::Header> object.

C<body> is a C<Mail::Message> object.
See L<Mail::Message> for more details.

=cut


# Descriptions: main delivery loop for each recipient_maps and each mta.
#               real delivery is done within _deliver() method.
#               algorithm:
#                 for each $map {
#                    for each $mta {
#                       call _deliver()
#                       send recipients up to $recipient_limit
#                    }
#                 }
#
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: See Mail::Delivery::Utils for recipient_map utilities
#               to track the delivery process status.
# Return Value: none
sub deliver
{
    my ($self, $args) = @_;

    # recipient limit
    $self->{_recipient_limit} = $args->{recipient_limit} || 1000;

    Log("debug: recipient_limit = $self->{_recipient_limit}");

    # temporary hash to check whether the map/mta is used already.
    my %used_mta = ();
    my %used_map = ();

    # prepare loop for each mta and map
    my @mta  = split(/\s+/, $args->{ smtp_servers } || '127.0.0.1:25');
    my @maps = ();
    if ( $args->{ recipient_maps } ) {
	@maps = split(/\s+/, $args->{ recipient_maps });
    }

    # alloc virtual recipient map
    if (ref( $args->{ recipient_array } ) eq 'ARRAY') {
	my $map = $args->{ recipient_array };
	push(@maps, $map);
    }


  MAP:
    for my $map ( @maps ) {
	# uniq $map
	next MAP if $used_map{ $map }; $used_map{ $map } = 1;

	# try to open $map
	eval q{
	    use IO::Adapter;
	    my $obj = new IO::Adapter $map, $args->{ map_params };
	    if (defined $obj) {
		$obj->open || croak("cannot open $map");
	    }
	};
	if ($@) {
	    $self->set_map_status($map, $MAP_ERR_OPEN);
	    Log("Error: cannot open and ignore $map");
	    next MAP;
	}

	$self->set_target_map($map);
	$self->set_map_status($map, $MAP_NOT_DONE);
	$self->set_map_position($map, 0);

	# XXX-TODO: correct $max_loop_count evaluation ?
	# To avoid infinite loop, we enforce some artificial limit.
	# The loop evaluation is limited to "2 * $number_of_mta" for each $map.
	my $loop_count     = 0;
	my $max_loop_count = int($#mta * 2) || 2;

      MTA_RETRY_LOOP:
	while (1) {
	    my $n_mta = 0;

	    # check infinite loop
	    if ($loop_count++ > $max_loop_count) {
		my $r = "too many smtp retry, give up map=$map";
		$self->error_set($r);
		last MTA_RETRY_LOOP;
	    }

	  MTA:
	    for my $mta (@mta) {
		# uniq $mta
		next MTA if $used_mta{ $mta }; $used_mta{ $mta } = 1;

		# avoid if error occurs.
		if ($self->get_mta_status($mta) eq $MTA_ERR_TIMEOUT) {
		    next MTA;
		}

		# count the number of effective mta in this inter loop.
		$n_mta++;

		# o.k. try to deliver mail by using $mta.
		Log("debug: use $mta for map=$map");
		$args->{ _mta } = $mta;
		$self->_deliver($args);

		# remove error messages for the next _deliver() session.
		$self->error_clear;

		# we read the whole $map now.
		if ($self->get_map_status($map) eq $MAP_DONE) {
		    last MTA;
		}
	    } # end of MTA: loop

	    # end of MTA_RETRY_LOOP: loop
	    if ($self->get_map_status($map) eq $MAP_DONE) {
		last MTA_RETRY_LOOP;
	    }

	    # NO effective mta in this inter loop. It impiles that
	    # we used all MTA candidates. We reuse @mta again.
	    if ($n_mta == 0) {
		Log("debug: we used all MTA candidates. reuse \$mta");
		my (@c) = keys %used_mta;
		Log("debug: candidates = (@c)");
		undef %used_mta;
		next MTA_RETRY_LOOP;
	    }
	}
    }

    # check map status.
  MAP:
    for my $map (@maps) {
	my $status = $self->get_map_status($map);
	next MAP if $status eq $MAP_ERR_OPEN;

	unless ($self->get_map_status($map) eq $MAP_DONE) {
	    $self->_fallback_into_queue($args, $map, $status);
	}
    }

    # clean up recipient_map information after "all delivery".
    # CAUTION: this mapinfo tracks the delivery status.
    $self->reset_mapinfo;

    if ( $self->{ _num_recipients } ) {
	my $n = $self->{ _num_recipients };
	Log("sent total=$n");
    }
}


# Descriptions: delivery fallback due to something error.
#               add this transaction into mail queue for later delivery.
#    Arguments: OBJ($self) HASH_REF($args) STR($map) STR($status)
# Side Effects: add this transaction into mail queue for later delivery.
# Return Value: none
sub _fallback_into_queue
{
    my ($self, $args, $map, $status) = @_;

    # log current status.
    my $n = $self->get_map_position($map) || 0;
    Log("map=$map pos=$n status=\"$status\"");

    # dump into queue.
    if (defined $args->{ use_queue_dir } && $args->{ use_queue_dir }) {
	my $queue_dir = $args->{ queue_dir } || '';
	if ($queue_dir && -d $queue_dir) {
	    my $msg      = $args->{ message }     || undef;
	    my $sender   = $args->{ smtp_sender } || '';
	    my $ra_rcpt  = [];
	    my $num_rcpt = 0;

            use IO::Adapter;
            my $obj = new IO::Adapter $map, $args->{ map_params };
            if (defined $obj) {
                $obj->open || do {
		    Log("cannot open $map");
		    Log("fatal: delivery fallback failed.");
		    return;
		};

		my $rcpt;
		while (defined ($rcpt = $obj->get_next_key)) {
		    $num_rcpt++;
		    push(@$ra_rcpt, $rcpt);
		}
            }

	    my $qid = '?';
	    eval q{
		croak("no sender") unless $sender;

		use Mail::Delivery::Queue;
		my $queue = new Mail::Delivery::Queue {
		    directory => $queue_dir,
		};

		$queue->set('sender', $sender);

		if (@$ra_rcpt) {
		    $queue->set('recipients', $ra_rcpt);
		}

		my $cur_print_mode = $msg->get_print_mode();
		$msg->set_print_mode('raw');
		$queue->in( $msg ) || croak("fail to queue in");
		{
		    my $error;
		    if ($error = $queue->error()) { Log("fallback: $error");}
		    my $n = $queue->write_count();
		    Log("queue: size=$n written");
		}
		$msg->set_print_mode($cur_print_mode);

		unless ($queue->setrunnable()) {
		    croak("fail to queue in");
		}

		$qid = $queue->id();
	    };
	    unless ($@) {
		Log("fallback: total=$num_rcpt qid=$qid");
	    }
	    else {
		Log("fallback error: $@");
		Log("fatal: delivery fallback failed.");
	    }
	}
    }
}


# Descriptions: ordinary SMTP sequence (see RFC821 for more details)
#              >220 I am some MTA ...
#              <EHLO/HELO myname
#              >250 ok
#              <MAIL FROM:<$sender>
#              >250 ok
#              <RCPT TO:<$recipient>
#              >250 oK
#              <DATA
#              >354 ...
#              < message
#              <.
#              >250 oK
#              <QUIT
#              >221 good bye
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: remove error messages when we return from here
#               for the next _deliver() session.
# Return Value: none
sub _deliver
{
    my ($self, $args) = @_;

    $self->_initialize_delivery_session($args);

    # prepare smtp information
    my $myhostname = $args->{ myhostname } || 'localhost';

    # 0. create BSD SOCKET as the communication terminal.
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    my $socket       = $self->_connect($args);
    my $is_connected = $self->is_socket_connected($socket);
    unless (defined($socket) && $is_connected) {
	my $mta = $args->{_mta} || 'unknown';
	Log("cannot connected to $mta");
	return undef;
    }
    else {
	my $mta = $args->{_mta} || 'unknown';
	Log("connected to $mta");
    }

    # 1. receive the first "220 .." message
    #    If you faces some error in this stage, you have to do nothing
    #    since smtp connection has not established yet.
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_read_reply;
    if ($self->error) {
	$self->_set_mta_as_ignored($args);
	return;
    }

    # 2. EHLO/HELO;
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_send_command("EHLO $myhostname");
    $self->_read_reply;
    if ($self->error) { $self->_reset_smtp_transaction($args);	return;}

    # 3. MAIL FROM;
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_send_mail_from($args);
    if ($self->error) { $self->_reset_smtp_transaction($args); return;}

    # 4. RCPT TO; ... send list of recipients
    #    IF_ERROR_FOUND: roll back the process to the state before this
    $self->_send_recipient_list($args);
    if ($self->error) {
	$self->rollback_map_position;
	$self->_reset_smtp_transaction($args);
	return;
    }

    # 5. DATA; send the mail body itself
    #    IF_ERROR_FOUND: handled in _send_data_to_mta(), so
    #                    return as soon as possible from here.
    $self->_send_data_to_mta($args);
    if ($self->error) {
	$self->rollback_map_position;
	$self->_reset_smtp_transaction($args);
	return;
    }

    # 6. QUIT; SMTP session closing ...
    #    IF_ERROR_FOUND: do nothing ?
    $self->_send_command("QUIT");
    $self->_read_reply;
    if ($self->error) { $self->_reset_smtp_transaction; return;}

    # o.k. succeded to deliver.
    my $n = $self->{ _num_recipients_in_this_transaction } || 0;
    if ($n) {
	my $mta = $args->{ _mta } || 'unknown';
	Log("sent num=$n mta=$mta");
	$self->{ _num_recipients } += $n;
    }
}


# Descriptions: initialize _deliver() process.
#               this routine is called at the first phase in _deliver().
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: initialize object
# Return Value: none
sub _initialize_delivery_session
{
    my ($self, $args) = @_;

    $self->set_last_command('');
    $self->set_status_code('');
}


############################################################
#####
##### MAIL FROM:
#####


# Descriptions: send SMTP command "MAIL FROM".
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
#     See Also: RFC821, RFC1123
#         TODO: VERP's
sub _send_mail_from
{
    my ($self, $args) = @_;
    my $sender = $args->{ smtp_sender };
    $self->_send_command("MAIL FROM:<$sender>");
    $self->_read_reply;
}



############################################################
#####
##### RCPT TO:
#####


# Descriptions: We evaluate recipient_maps parameter here.
#               You can use a lot of classes for this directive: e.g.
#               file, UNIX's /etc/group, YP, SQL, LDAP, ...
#               Example: recipient_maps = file:members
#                                         unix.group:admin
#                                         mysql:toymodel
#               IO::Adapter class is essential to handle abstract
#               $recipient_map.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: $self->{ _retry_recipient_table } has recipients which
#               causes some errors.
#               _{set,get}_map_position() and _{set,get}_map_status()
#               tracks the delivery process.
# Return Value: none
sub _send_recipient_list_by_recipient_map
{
    my ($self, $args) = @_;
    my $map = $self->get_target_map;

    # open abstract recipient list objects.
    # $map syntax is "type:parameter", e.g.,
    # file:$filename mysql:$schema_name
    use IO::Adapter;
    my $obj = new IO::Adapter  $map, $args->{ map_params };

    unless (defined $obj) {
	Log("Error: fail to create map=$map object.");
    }
    else { # $obj is good.
	my $rcpt;
	my $num_recipients = 0;
	my $recipient_limit = $self->{_recipient_limit};

	$obj->open || do {
	    $self->error_set( $obj->error );
	    return undef;
	};

	# roll back the previous file offset
	if ($self->get_map_position($map) > 0) {
	    $obj->setpos( $self->get_map_position($map) );
	}

	# XXX $obj->get_recipient returns a mail address.
      RCPT_INPUT:
	while (defined ($rcpt = $obj->get_next_key)) {
	    $num_recipients++;
	    $self->_send_command("RCPT TO:<$rcpt>");
	    $self->_read_reply;

	    # save addresses to retry later.
	    my $action = $self->get_send_command_status();
	    if ($action eq $SMTP_ERR_RETRY) {
		$self->{ _retry_recipient_table }->{ $rcpt } = $SMTP_ERR_RETRY;
	    }

	    last RCPT_INPUT if $num_recipients >= $recipient_limit;
	}

	# save the current position in the file handle
	$self->set_map_position($map, $obj->getpos);

	# done.
	if ($obj->eof) {
	    $self->set_map_status($map, $MAP_DONE);
	}

	# ends
	$obj->close;

	# count up the total number of recipients
	$self->{ _num_recipients_in_this_transaction } = $num_recipients;

	unless ($num_recipients) {
	    Log("Error: no recipients for $map");
	    $self->_send_command("RSET");
	    $self->_read_reply;
	}
    }
}


# Descriptions: send "RCPT TO:<recipient>" to MTA.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _send_recipient_list
{
    my ($self, $args) = @_;

    # evaluate recipient_maps
    if ( $self->get_target_map ) {
	$self->_send_recipient_list_by_recipient_map($args);
    }
}


############################################################
#####
##### DATA:
#####

# Descriptions: send the header part of the message to socket
#    Arguments: OBJ($self) HANDLE($socket) OBJ($header)
#               $ref_to_header is the FML::Header class object.
# Side Effects: none
# Return Value: none
sub _send_header_to_mta
{
    my ($self, $socket, $header) = @_;

    # get header
    my $h = $header->as_string($socket);
    $h =~ s/\n/\r\n/g;
    print $socket $h;
    $self->smtplog($h);
}


# Descriptions: send the body part of the message to socket
#    Arguments: OBJ($self) HANDLE($socket) OBJ($msg)
# Side Effects: none
# Return Value: none
sub _send_body_to_mta
{
    my ($self, $socket, $msg) = @_;

    # XXX $msg is Mail::Message object.
    $msg->set_log_function($SmtpLogFunctionPointer, $SmtpLogFunctionPointer);
    $msg->set_print_mode('smtp');
    $msg->print($socket);

    if (defined $self->{ _smtp_log_handle }) {
	$msg->print( $self->{ _smtp_log_handle });
    }

    $msg->unset_log_function();
}


# Descriptions: send message itself to file handle (BSD socket here).
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _send_data_to_mta
{
    my ($self, $args) = @_;

    # prepare smtp information
    my $header = $args->{ message }->whole_message_header;
    my $body   = $args->{ message }->whole_message_body;
    my $socket = $self->{'_socket'};

    if (defined $body) {
	$self->_send_command("DATA");
	$self->_read_reply;

	# XXX if "DATA" transaction cannot start, retry ?
	if ($self->get_status_code != '354' || $self->error) {
	    Log($self->error);
	    return undef;
	}

	# 1. header; send header
	$self->_send_header_to_mta($socket, $header);

	# 2. separator between header and body
	print $socket "\r\n";
	$self->smtplog("\r\n");

	# 3. body; send(copy) body on memory to socket each line
	$self->_send_body_to_mta($socket, $body);

	# end "DATA" transaction
	$self->_send_command("\r\n.");
	$self->_read_reply;
    }
}


############################################################
#####
##### QUIT / RSET
#####


# Descriptions: send the SMTP reset "RSET" command.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _reset_smtp_transaction
{
    my ($self, $args) = @_;

    # mark this mta is invalid.
    $self->_set_mta_as_ignored($args);

    # reset SMTP transaction.
    $self->_send_command("RSET");
    $self->_read_reply;
    Log("reset smtp transcation");
}


# Descriptions: mark this mta should be ignored.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _set_mta_as_ignored
{
    my ($self, $args) = @_;

    # mark this mta is invalid.
    my $mta = $args->{ _mta } || '';
    if ($mta) {
	$self->set_mta_status($mta, $MTA_ERR_TIMEOUT);
    }
}


=head1 SEE ALSO

L<IO::Socket>,
L<Mail::Delivery::Utils>,
L<Mail::Delivery::INET4>,
L<Mail::Delivery::INET6>,
L<IO::Adapter>

See I<http://www.postfix.org/> on C<Postfix>
which replaces sendmail with little effort
but provides a lot of compatibility except for sendmail.cf.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::SMTP first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
