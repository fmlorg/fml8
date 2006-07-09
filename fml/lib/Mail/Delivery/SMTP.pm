#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003,2004,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: SMTP.pm,v 1.48 2006/04/22 08:55:33 fukachan Exp $
#


package Mail::Delivery::SMTP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::Socket;

# Mail::Delivery::SMTP IS-A Mail::Delivery::Protocol.
use Mail::Delivery::Protocol;
@ISA = qw(Mail::Delivery::Protocol);

BEGIN {}
END   {}

# MAP IO STATUS CODE
my $MAP_DONE     = 'DONE';
my $MAP_NOT_DONE = 'NOT DONE';
my $MAP_ERR_OPEN = 'CANNOT OPEN';

# MTA IO STATUS CODE
my $MTA_OK          = 'OK';
my $MTA_ERR_TIMEOUT = 'TIMEOUT';
my $MTA_ERR_FATAL   = 'FATAL';

# SMTP STATUS
my $SMTP_OK         = 'OK';
my $SMTP_ERR_RETRY  = 'SMTP RETRY';
my $SMTP_ERR_FATAL  = 'SMTP FATAL ERROR';


=head1 NAME

Mail::Delivery::SMTP - interface for SMTP service

=head1 SYNOPSIS

To initialize,

    use Mail::Message;

      ... make $message (Mail::Message object) ...

    use Mail::Delivery::SMTP;
    my $fp  = sub { $curproc->log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    my $service = new Mail::Delivery::SMTP {
        log_function       => $fp,
        smtp_log_function  => $sfp,
        default_io_timeout => 10,
    };
    if ($service->error) { $curproc->logerror($service->error); return;}

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

    $me->{ _num_recipients } = 0;

    bless $me, $type;

    $me->set_smtp_recipient_limit($args->{ recipient_limit }    || 1000);
    $me->set_smtp_default_timeout($args->{ default_io_timeout } || 10);
    $me->_set_queue_directory($args->{ queue_dir } || '');

    my $fp_address_validate = $args->{address_validate_function} || undef;
    $me->set_address_validate_function($fp_address_validate);

    $me->_init_delivery_transaction($args);
    $me->_init_logging($args);

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
    my $socket = $self->get_socket() || undef;

    unless (defined $socket) {
	$self->logerror("_send_command: undefined socket");
    }

    $self->set_last_command($command);
    $self->set_send_command_status('');
    $self->smtplog($command."\r\n");

    if (defined $socket) {
	$socket->print($command, "\r\n");
    }
    else {
	$self->logerror("_send_command: undefined socket");
    }
}


# Descriptions: receive a reply for a (SMTP/LMTP) command.
#    Arguments: OBJ($self)
# Side Effects: update log file by smtplog.
# Return Value: none
sub _read_reply
{
    my ($self) = @_;
    my $socket = $self->get_socket() || undef;

    # unique identifier to clarify the trapped error message
    my $id = sprintf("%s-%s", time, $$);

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
	alarm( $self->get_smtp_default_timeout() );
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
		    $self->_set_attribute("use_pipelining", "yes");
		}
		if ($buf =~ /^250.ETRN/i) {
		    $self->_set_attribute("use_etrn", "yes");
		}
		if ($buf =~ /^250.SIZE\s+(\d+)/i) {
		    $self->_set_attribute("size_limit", $1);
		}
	    }

	    # store the latest status code
	    if ($buf =~ /^(\d{3})/) { $self->set_status_code($1);}

	    # check status code
	    if ($buf =~ /^[45]\d{2}\s/) {
		my $command = $self->get_last_command();
		$self->logerror(sprintf("%s ... %s", $command, $buf));
		die("$id temprary failure") if $buf =~ /^4/;
		die("$id fatal")            if $buf =~ /^5/;
	    }

	    # end of reply e.g. "250 ..."
	    last SMTP_REPLY if $buf =~ /^\d{3}\s/;
	}
    };

    if ($@ =~ /$id temprary failure/) {
	$self->set_send_command_status($SMTP_ERR_RETRY);
	$self->logerror("temporary failure, retry");
	$self->set_error("temporary failure, retry");
    }
    elsif ($@ =~ /$id fatal/) {
	$self->set_send_command_status($SMTP_ERR_FATAL);
	$self->logerror("fatal error");
	$self->set_error("fatal error");
    }
    elsif ($@ =~ /$id socket timeout/) {
	my $command = $self->get_last_command();
	$self->logerror("smtp reply for \"$command\" is timeout");
	$self->set_error("smtp reply for \"$command\" is timeout");
    }
    elsif ($@) {
	$self->logerror($@);
	$self->set_error($@);
    }

    # reset latest alarm() setting
    alarm(0);
}


# Descriptions: connect(2)
#               1. try connect(2) by IPv6 if we can use Socket6.pm
#               2. try connect(2) by IPv4
#                  if $host is not IPv6 raw address e.g. [::1]:25
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: set file handle (BSD socket) in $self->{_socket}
# Return Value: HANDLE(created BSD socket) or undef()
sub _connect
{
    my ($self, $args) = @_;
    my $mta = $args->{ mta } || '127.0.0.1:25';

    $self->clear_error;

    # 1. try to connect(2) $mta by IPv6 if
    #    (1) we can use Socket6.
    #    (2) mta is not pure IPv4 syntax (Iv6 syntax or hostname).
    if ($self->is_ipv6_ready() && (! $self->is_pure_ipv4_syntax($mta))) {
	$self->logdebug("try mta=$mta by IPv6");
	$self->connect6($mta);
	my $socket = $self->get_socket() || undef;
	if (defined $socket) {
	    return $socket;
	}
	else {
	    $self->logerror("cannot connect $mta");
	}
    }
    else {
	$self->logdebug("IPv6 is not ready");
    }

    $self->clear_error;

    # 2. try to connect(2) $mta by IPv4.
    #    XXX check the mta syntax.
    #    XXX if $mta looks [$ipv6_addr]:$port style,
    #    XXX we do not try to connect the host by IPv4.
    if ($self->is_ipv6_mta_syntax($mta)) {
	$self->logdebug("not try MTA $mta");
	return undef;
    }
    else {
	$self->logdebug("try mta=$mta by IPv4");
	my $socket = $self->connect4($mta);
	if (defined $socket) {
	    return $socket;
	}
	else {
	    $self->logerror("cannot connect $mta");
	    return undef;
	}
    }

    return undef;
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

    # smtp_recipient_limit: maximum recipients in one smtp session.
    #      default_timeout: basic timeout parameter for smtp session
    $self->set_smtp_recipient_limit($args->{ recipient_limit }    || 1000);
    $self->set_smtp_default_timeout($args->{ default_io_timeout } || 10);
    $self->_set_queue_directory($args->{ queue_dir } || '');

    # temporary hash to check whether the map/mta is used already.
    my %used_mta   = ();
    my %used_map   = ();

    # prepare loop for each mta and map
    my $mta  = $self->_get_mta_list($args);
    my $maps = $self->_get_map_list($args);

  MAP:
    for my $map ( @$maps ) {
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
	    $self->logerror("cannot open and ignore $map");
	    next MAP;
	}

	if ($self->get_map_status($map) eq $MAP_ERR_OPEN) {
	    next MAP;
	}

	$self->set_target_map($map);
	$self->set_map_status($map, $MAP_NOT_DONE);
	$self->set_map_position($map, 0);

	# To avoid infinite loop, we enforce some artificial limit.
	my $loop_count     = 0;
	my $max_retry      = 1024 * 1024 * 512 * ($#$mta + 1);
	my $max_loop_count = $args->{ mta_max_retry } || $max_retry;

      MTA_RETRY_LOOP:
	while (1) {
	    my $n_mta = 0;

	    # avoid infinite loop
	    if ($self->_is_stop_loop($loop_count++, $max_loop_count)) {
		$self->logdebug("too many smtp retry, give up map=$map");
		$self->set_error("too many smtp retry, give up");
		last MTA_RETRY_LOOP;
	    }

	    # check the number of effective MTA's.
	    {
		my $is_valid_mta = 0;
	      MTA:
		for my $mta (@$mta) {
		    unless ($self->get_mta_status($mta) eq $MTA_ERR_TIMEOUT ||
			    $self->get_mta_status($mta) eq $MTA_ERR_FATAL   ) {
			$is_valid_mta++;
		    }
		}
		unless ($is_valid_mta) {
		    $self->log("no valid MTA");
		    last MTA_RETRY_LOOP;
		}
	    }

	  MTA:
	    for my $mta (@$mta) {
		# not retry to broken MTA.
		# we may use a normal MTA frequently in results.
		if ($self->get_mta_status($mta) eq $MTA_ERR_TIMEOUT ||
		    $self->get_mta_status($mta) eq $MTA_ERR_FATAL   ) {
		    $self->logdebug("ignore $mta (fatal)");
		    next MTA;
		}
		else {
		    if ($used_mta{ $mta }) {
			$self->logdebug("not try $mta (cached)");
		    }
		    else {
			$self->logdebug("try $mta");
		    }
		}

		# uniq $mta
		next MTA if $used_mta{ $mta }; $used_mta{ $mta } = 1;

		# count the number of effective mta in this inter loop.
		$n_mta++;

		# o.k. try to deliver mail by using $mta.
		$self->logdebug("use $mta for map=$map");
		$args->{ mta } = $mta;
		$self->_deliver($args);

		if ($self->get_map_status($map) eq $MAP_ERR_OPEN) {
		    next MAP;
		}

		# we read the whole $map now.
		if ($self->get_map_status($map) eq $MAP_DONE) {
		    last MTA;
		}
	    } # MTA: loop

	    if ($self->get_map_status($map) eq $MAP_DONE) {
		last MTA_RETRY_LOOP;
	    }

	    # NO effective mta in this inter loop. It impiles that
	    # we used all MTA candidates. We reuse @mta again.
	    if ($n_mta == 0) {
		$self->logdebug("we used all MTA candidates. reuse \$mta");
		my (@c) = keys %used_mta;
		$self->logdebug("candidates = (@c)");
		undef %used_mta;
		next MTA_RETRY_LOOP;
	    }
	} # MTA_RETRY_LOOP loop
    } # MAP loop

    # check map status.
  MAP:
    for my $map (@$maps) {
	my $status = $self->get_map_status($map);
	next MAP if $status eq $MAP_ERR_OPEN;

	unless ($self->get_map_status($map) eq $MAP_DONE) {
	    $self->_fallback_into_queue($args, $map, $status);
	}
    }

    # clean up recipient_map information after "all delivery".
    # CAUTION: this mapinfo tracks the delivery status.
    $self->clear_mapinfo;

    if ( $self->{ _num_recipients } ) {
	my $n     = $self->{ _num_recipients };
	my $queue = $args->{ queue } || undef;
	my $qid   = defined($queue) ? $queue->id() : '';
	if ($qid) {
	    $self->log("status=sent total=$n qid=$qid");
	}
	else {
	    $self->log("status=sent total=$n");
	}

	use File::Basename;
	my (@m) = ();
	for my $m (@$maps) { push(@m, basename($m));}
	$self->logdebug("status=sent total=$n maps=(@m)");
    }
}


# Descriptions: check if this loop should stop or not.
#    Arguments: OBJ($self) NUM($count) NUM($limit)
# Side Effects: none
# Return Value: none
sub _is_stop_loop
{
    my ($self, $count, $limit) = @_;

    my $penalty_cost = $self->_get_retry_penalty() || 1;
    my $max_count    = int( $limit / $penalty_cost );
    $self->logdebug("stop? $count > $max_count");
    if ($count > $max_count) {
	$self->logerror("too many error! $count > $max_count");
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: check if the specified map exists within queue or not.
#    Arguments: OBJ($self) STR($map)
# Side Effects: none
# Return Value: NUM
sub _is_map_in_queue
{
    my ($self, $map) = @_;
    my $queue_dir = $self->_get_queue_directory() || '';

    if ($queue_dir && $map && $map =~ /$queue_dir/) {
        return 1;
    }
    else {
        return 0;
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
    my $queue = $args->{ queue } || undef;

    # ASSERT
    my $retry_count  = $queue->get_retry_count()     || 0;
    my $in_queue_dir = $self->_is_map_in_queue($map) || 0;
    my $map_position = $self->get_map_position($map) || 0;
    if ($in_queue_dir && $retry_count > 0 && $map_position == 0) {
	# XXX we should hold this old queue as it is.
	$self->log("not need fallback, retry=$retry_count pos=0");
	$self->set_not_done();
	return;
    }
    else {
	my $msg = "in=$in_queue_dir retry=$retry_count pos=$map_position";
	$self->log("fallback: (debug) $msg");
    }

    # log current status.
    my $pos = $self->get_map_position($map) || 0;
    $self->logdebug("map=$map pos=$pos status=\"$status\"");

    # dump into queue.
    if (defined $args->{ use_queue_dir } && $args->{ use_queue_dir }) {
	my $queue_dir = $args->{ queue_dir } || '';
	if ($queue_dir && -d $queue_dir) {
	    my $msg        = $args->{ message }     || undef;
	    my $sender     = $args->{ smtp_sender } || '';
	    my $ra_rcpt    = [];
	    my $rcpt_total = 0;

            use IO::Adapter;
            my $obj = new IO::Adapter $map, $args->{ map_params };
            if (defined $obj) {
                $obj->open || do {
		    $self->logerror("cannot open $map");
		    $self->logerror("fatal: delivery fallback failed.");
		    return;
		};

		if ($pos) {
		    $obj->setpos($pos);
		}

		my $rcpt;
		while (defined ($rcpt = $obj->get_next_key)) {
		    $rcpt_total++;
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
		    if ($error = $queue->error()) {
			$self->logerror("fallback: $error");
		    }
		    my $n = $queue->write_count();
		    $self->logdebug("queue: size=$n written");
		}
		$msg->set_print_mode($cur_print_mode);

		unless ($queue->setrunnable()) {
		    $self->logerror("queue-in failed.");
		}

		$qid = $queue->id();

		# into deferred queue for later retry.
		$queue->sleep_queue();
	    };
	    unless ($@) {
		$self->log("fallback: total=$rcpt_total qid=$qid");
	    }
	    else {
		$self->logerror("fallback error: $@");
		$self->logerror("fatal: delivery fallback failed.");
	    }
	}
	else {
	    $self->logerror("fallback error: no queue");
	}
    }
    else {
	$self->logerror("fallback error: no queue");
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

    # reset error messages.
    $self->clear_error;

    $self->_init_delivery_transaction($args);

    # prepare smtp information
    my $myhostname = $args->{ myhostname } || 'localhost';

    # 0. create BSD SOCKET as the communication terminal.
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    my $socket       = $self->_connect($args);
    my $is_connected = $self->is_socket_connected($socket);
    unless (defined($socket) && $is_connected) {
	my $mta = $args->{mta} || 'unknown';
	$self->logdebug("cannot connect to $mta");
	$self->_set_mta_as_fatal($args);
	return undef;
    }
    else {
	my $mta = $args->{mta} || 'unknown';
	$self->logdebug("connected to $mta");
    }

    # 1. receive the first "220 .." message
    #    If you faces some error in this stage, you have to do nothing
    #    since smtp connection has not established yet.
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_read_reply;
    if ($self->get_error) {
	$self->_set_mta_as_timeout($args);
	$self->_set_mta_as_fatal($args);
	return;
    }

    # 2. EHLO/HELO;
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_send_command("EHLO $myhostname");
    $self->_read_reply;
    if ($self->get_error) {
	$self->clear_error;
	$self->_reset_smtp_transaction($args);

	# if EHLO fails, try HELO.
	$self->_send_command("HELO $myhostname");
	$self->_read_reply;
	if ($self->get_error) {
	    $self->_reset_smtp_transaction($args);
	    $self->_set_mta_as_fatal($args);
	    return;
	}
    }

    # 3. MAIL FROM;
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_send_mail_from($args);
    if ($self->get_error) {
	$self->_reset_smtp_transaction($args);
	$self->_set_mta_as_fatal($args);
	return;
    }

    # 4. RCPT TO; ... send list of recipients
    #    IF_ERROR_FOUND: roll back the process to the state before this
    $self->_send_recipient_list($args);
    if ($self->get_error) {
	$self->rollback_map_position;
	$self->_set_retry_penalty(); # XXX rollback gains penalty.
	$self->_reset_smtp_transaction($args);
	$self->_set_mta_as_fatal($args);
	return;
    }

    # 5. DATA; send the mail body itself
    #    IF_ERROR_FOUND: handled in _send_data_to_mta(), so
    #                    return as soon as possible from here.
    $self->_send_data_to_mta($args);
    if ($self->get_error) {
	$self->rollback_map_position;
	$self->_reset_smtp_transaction($args);
	$self->_set_mta_as_fatal($args);
	return;
    }

    # 6. QUIT; SMTP session closing ...
    #    IF_ERROR_FOUND: do nothing ?
    $self->_send_command("QUIT");
    $self->_read_reply;
    if ($self->get_error) {
	$self->_reset_smtp_transaction;
	$self->_set_mta_as_fatal($args);
	return;
    }

    # o.k. succeded to deliver.
    my $n = $self->{ _num_recipients_in_this_transaction } || 0;
    if ($n) {
	my $mta = $args->{ mta } || 'unknown';
	$self->logdebug("status=sent total=$n mta=$mta");
	$self->{ _num_recipients } += $n;
    }
}


# Descriptions: initialize _deliver() process.
#               this routine is called at the first phase in _deliver().
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: initialize object
# Return Value: none
sub _init_delivery_transaction
{
    my ($self, $args) = @_;

    $self->set_last_command('');
    $self->set_status_code('');
}


# Descriptions: initialize logging interface.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _init_logging
{
    my ($self, $args) = @_;

    # default logging interface (infomational).
    my ($fp_log_info) = $args->{ log_info_function } || undef;
    if (defined $fp_log_info) { $self->set_log_info_function($fp_log_info);}

    # error level log.
    my ($fp_log_error) = $args->{ log_error_function } || undef;
    if (defined $fp_log_error) { $self->set_log_error_function($fp_log_error);}

    # debug level log.
    my ($fp_log_debug) = $args->{ log_debug_function } || undef;
    if (defined $fp_log_debug) { $self->set_log_debug_function($fp_log_debug);}

    # smtp transaction logging interface.
    my ($fp_smtp_log) = $args->{ smtp_log_function } || undef;
    if (defined $fp_smtp_log) { $self->set_smtp_log_function($fp_smtp_log);}

    my ($handle) = $args->{smtp_log_handle} || undef;
    if (defined $handle) { $self->set_smtp_log_handle($handle);}
}


# Descriptions: get MTA list as ARRAY_REF.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_mta_list
{
    my ($self, $args) = @_;
    my $list = $args->{ smtp_servers } || '127.0.0.1:25';
    $list =~ s/^\s*//;
    $list =~ s/\s*$//;

    my (@mta) = split(/\s+/, $list);
    return \@mta;
}


# Descriptions: get map list as ARRAY_REF.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_map_list
{
    my ($self, $args) = @_;
    my (@maps) = ();

    if ($args->{ recipient_maps }) {
	@maps = split(/\s+/, $args->{ recipient_maps });
    }

    # alloc virtual recipient map
    if (ref( $args->{ recipient_array } ) eq 'ARRAY') {
	my $map = $args->{ recipient_array };
	push(@maps, $map);
    }

return \@maps;
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

    if (defined $sender) {
	$self->_send_command("MAIL FROM:<$sender>");
	$self->_read_reply;
    }
    else {
	$self->logerror("smtp_sender undefined");
    }
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

    use IO::Adapter;
    my $obj = new IO::Adapter $map, $args->{ map_params };
    unless (defined $obj) {
	$self->set_map_status($map, $MAP_ERR_OPEN);
	$self->logerror("fail to create map=$map object.");
	return undef;
    }

    my $rcpt;
    my $num_recipients = 0;
    my $recipient_limit = $self->get_smtp_recipient_limit();

    $obj->open || do {
	$self->set_error( $obj->error );
	return undef;
    };

    # roll back the previous file offset
    if ($self->get_map_position($map) > 0) {
	$obj->setpos( $self->get_map_position($map) );
    }

    # address validate function.
    my $fp_address_validate = $self->get_address_validate_function();

    # XXX $obj->get_recipient returns a mail address.
  RCPT_INPUT:
    while (defined ($rcpt = $obj->get_next_key)) {
	# firstly, validate the format of the specified address $rcpt.
	if (defined $fp_address_validate) {
	    my $r = 0;
	    eval q{ $r = &$fp_address_validate($rcpt);};
	    unless ($@) {
		unless ($r) {
		    $self->smtplog("==> ignore invalid recipient <$rcpt>");
		    $self->logerror("invalid recipient <$rcpt>");
		    next RCPT_INPUT;
		}
	    }
	    else {
		$self->logerror("cannot call address validate function");
	    }
	}

	$num_recipients++;

	$self->_send_command("RCPT TO:<$rcpt>");
	$self->_read_reply;

	# save addresses to retry later.
	my $action = $self->get_send_command_status();
	if ($action eq $SMTP_ERR_RETRY) {
	    # XXX-TODO: actual code required.
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
	$self->logerror("no recipient for $map");
	$self->_send_command("RSET");
	$self->_read_reply;
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

    # ASSERT
    unless (defined $socket) {
	$self->logerror("_send_header_to_mta: socket undefined");
	return;
    }
    unless (defined $header) {
	$self->logerror("_send_header_to_mta: header undefined");
	return;
    }

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

    # ASSERT
    unless (defined $socket) {
	$self->logerror("_send_body_to_mta: socket undefined");
	return;
    }
    unless (defined $msg) {
	$self->logerror("_send_body_to_mta: message undefined");
	return;
    }

    # XXX $msg is Mail::Message object.
    my $fp = $self->get_smtp_log_function();
    $msg->set_log_function($fp, $fp);
    $msg->set_print_mode('smtp');
    $msg->print($socket);

    my $wh = $self->get_smtp_log_handle();
    if (defined $wh) {
	$msg->print( $wh );
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
    my $socket = $self->get_socket() || undef;

    if (defined $body) {
	$self->_send_command("DATA");
	$self->_read_reply;

	# XXX if "DATA" transaction cannot start, retry ?
	if ($self->get_status_code != '354' || $self->get_error) {
	    $self->logerror($self->get_error);
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
    $self->_set_mta_as_timeout($args);

    # reset SMTP transaction.
    $self->_send_command("RSET");
    $self->_read_reply;
    $self->log("reset smtp transcation");
}


# Descriptions: mark this mta should be ignored.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _set_mta_as_timeout
{
    my ($self, $args) = @_;

    my $mta = $args->{ mta } || '';
    if ($mta) {
	$self->set_mta_status($mta, $MTA_ERR_TIMEOUT);
    }
}


# Descriptions: mark this mta should be ignored.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _set_mta_as_fatal
{
    my ($self, $args) = @_;

    my $mta = $args->{ mta } || '';
    if ($mta) {
	$self->set_mta_status($mta, $MTA_ERR_FATAL);
    }
}


# Descriptions: set attributes
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: update $self
# Return Value: none
sub _set_attribute
{
	my ($self, $key, $value) = @_;
	$self->{ _attr }->{ $key } = $value;
}


# Descriptions: get attributes
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub _get_attribute
{
	my ($self, $key, $value) = @_;
	return ( $self->{ _attr }->{ $key } || undef );
}


# Descriptions: set retry penalty cost.
#    Arguments: OBJ($self)
# Side Effects: update $self
# Return Value: none
sub _set_retry_penalty
{
    my ($self) = @_;

    my $penalty = $self->{ _retry_penalty } || 1;
    $self->{ _retry_penalty } = 2 * $penalty;
}


# Descriptions: get retry penalty cost.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub _get_retry_penalty
{
    my ($self) = @_;

    return ($self->{ _retry_penalty } || 1);
}


# Descriptions: save queue_directory.
#    Arguments: OBJ($self) STR($queue_dir)
# Side Effects: update $self
# Return Value: none
sub _set_queue_directory
{
    my ($self, $queue_dir) = @_;
    $self->{ _queue_directory } = $queue_dir || '';
}

# Descriptions: return queue_directory.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub _get_queue_directory
{
    my ($self) = @_;

    return( $self->{ _queue_directory } || '' );
}


# Descriptions: set NOT DONE flag.
#    Arguments: OBJ($self)
# Side Effects: update $self
# Return Value: none
sub set_not_done
{
    my ($self) = @_;
    $self->{ _not_done } = 1;
}


# Descriptions: check NOT DONE flag.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_not_done
{
    my ($self) = @_;
    return( $self->{ _not_done } || 0 );
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

Copyright (C) 2000,2001,2002,2003,2004,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::SMTP first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
