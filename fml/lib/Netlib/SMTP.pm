#-*- perl -*-
#
#  Copyright (C) 2000-2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#


package Netlib::SMTP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::Socket;
use Netlib::Utils;
use Netlib::INET4;
use Netlib::INET6;

require Exporter;
@ISA = qw(Exporter);


BEGIN {}


=head1 NAME

Netlib::SMTP.pm - interface for SMTP service

=head1 SYNOPSIS

To initialize, 

    use Netlib::SMTP;
    my $fp  = sub { Log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    my $service = new Netlib::SMTP {
        log_function       => $fp,
        smtp_log_function  => $sfp,
        socket_timeout     => 2,     # XXX 2 for debug but 10 by default
    };
    if ($service->error) { Log($service->error); return;}

To start delivery, use deliver() method in this way.

    $service->deliver(
                      {
                          mta             => '127.0.0.1:25',

                          smtp_sender     => 'rudo@nuinui.net',
                          recipient_maps  => $recipient_maps,
                          recipient_limit => 1000,

                          header          => $header_object,
                          body            => $body_object,
                      });

=head1 DESCRIPTION

=head1 METHODS

=item C<new()>

constructor. If you control parameters, specify it in a hash reference
as an argument of new().

        hash key           value
        --------------------------------------------
        log_function       reference to function for logging
        smtp_log_function  reference to function for logging
        socket_timeout     set the timeout associated with the socket

log_function() is for general purpose.
smtp_log_function() is used to log SMTP transactions.

=cut

# Descriptions: Netlib::SMTP constructor
#    Arguments: $self $args
# Side Effects: $self ($me) hash has some default values
# Return Value: object
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {}; # malloc new SMTP session struct

    # _recipient_limit: maximum recipients in one smtp session.
    #  _socket_timeout: basic timeout parameter for smtp session
    #    _log_function: pointer to the log() function
    $me->{_recipient_limit} = $args->{recipient_limit} || 1000;
    $me->{_socket_timeout}  = $args->{socket_timeout}  || 10;
    $me->{_log_function}      = $args->{log_function};
    $me->{_smtp_log_function} = $args->{smtp_log_function};

    _initialize_delivery_session($me, $args);

    # define package global pointer to the log() function
    $LogFunctionPointer     = $args->{log_function};
    $SmtpLogFunctionPointer = $args->{smtp_log_function};

    return bless $me, $type;
}


# Descriptions: send a (SMTP/LMTP) command string to BSD socket
#    Arguments: $self $command_string
# Side Effects: log file by _smtplog
#               set _last_command and _error_action in object itself
# Return Value: none
sub _send_command
{
    my ($self, $command) = @_;
    my $socket = $self->{'_socket'};

    $self->{_last_command} = $command;
    $self->{_error_action} = '';
    $self->smtplog($command);

    if (defined $socket) {
	$socket->print($command, "\r\n");
    }
    else {
	Log("Error: _send_command: undefined socket");
    }
}


# Descriptions: receive a reply for a (SMTP/LMTP) command
#    Arguments: $self
# Side Effects: log file by _smtplog
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
    if ($self->{_last_command} =~ /^(EHLO|HELO|LHLO)/) {
	$check_attributes = 1;
    }

    # XXX Attention! dynamic scope by local() for %SIG is essential.
    #     See books on Perl for more details on my() and local() difference.
    eval {
	local($SIG{ALRM}) = sub { die("$id socket timeout")}; 
	alarm( $self->{_socket_timeout} );
	my $buf = '';

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
	    if ($buf =~ /^(\d{3})/) { $self->_set_status_code($1);}

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
	$self->{'_error_action'} = "retry";
    }

    if ($@ =~ /$id socket timeout/) {
	my $x = $self->{'_last_command'};
	Log("Error: smtp reply for \"$x\" is timeout");
	$self->_error_why("Error: smtp reply for \"$x\" is timeout");
    }
}


# Descriptions: connect(2)
#               1. try connect(2) by IPv6 if we can use Socket6.pm
#               2. try connect(2) by IPv4
#                  if $host is not IPv6 raw address e.g. [::1]:25
#    Arguments: $self $args
# Side Effects: set file handle (BSD socket) in $self->{_socket}
# Return Value: file handle (created BSD socket) or undef()
sub _connect
{
    my ($self, $args) = @_;
    my $mta = $args->{'_mta'} || '127.0.0.1:25';
    my $socket;

    # 1. try to connect(2) $args->{ _mta } by IPv6 if we can use Socket6.
    if ($self->is_ipv6_ready($args)) {
	$self->_connect6($args);
	my $socket = $self->{_socket};
	return $socket if defined $socket;
    }
    else {
	Log("(debug) IPv6 is not ready");
    }

    # 2. try to connect(2) $args->{ _mta } by IPv4.
    #    XXX check the _mta syntax.
    #    XXX if $args->{ _mta } looks [$ipv6_addr]:$port style,
    #    XXX we do not try to connect the host by IPv4.
    if ( $self->is_ipv6_mta_syntax($mta) ) {
	Log("(debug) not try MTA $args->{_mta}");
	return undef;
    }
    else {
	$self->_connect4($args);
    }
}


# Descriptions: close BSD socket
#    Arguments: $self
# Side Effects: 
# Return Value: none
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

=item C<deliver()>

start delivery process.

        hash key           value
        --------------------------------------------
        mta                127.0.0.1:25 [::1]:25
        smtp_sender        sender's mail address
        recipient_maps     $recipient_maps
        recipient_limit    recipients in one SMTP transactions
        header             FML::Header object
        body               Netlib::Messages object

C<mta> is a list of MTA's.
The syntax of each MTA is address:port style. 
If you use a raw IPv6 address, use [address]:port syntax. 
For example, [::1]:25 (v6 loopback).
You can specify IPv4 and IPv6 addresses.
deliver() automatically tries smtp in both protocols.

C<smtp_sender> is the sender's email address. It is used at MAIL FROM:
parameter.

C<recipient_maps> is a list of C<maps>.
See L<IO::MapAdapter> for more details. 
For example,

to read address from a file

         file:/var/spool/ml/elena/recipients

to read addresses from /etc/group

         unix.group:fml

C<recipient_limit> is the max number of recipients in one SMTP
transaction. 1000 by default, which corresponds to the limit by Postfix. 

C<header> is FML::Header object.

C<body> is Netlib::Messages object.
See L<Netlib::Messages> for more details.

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
#    Arguments: $self $args
# Side Effects: See Netlib::Utils for recipient_map utilities 
#               to track the delivery process status.
# Return Value: none
sub deliver
{
    my ($self, $args) = @_;

    # recipient limit
    $self->{_recipient_limit} = $args->{recipient_limit} || 1000;

    # temporary hash to check whether the map/mta is used already.
    my %used_mta = ();
    my %used_map = ();

    # prepare loop for each mta and map 
    my @mta  = split(/\s+/, $args->{ mta } || '127.0.0.1:25');
    my @maps = ();
    if ( $args->{ recipient_maps } ) {
	@maps = split(/\s+/, $args->{ recipient_maps });
    }

    # alloc virtual recipient map
    if (ref( $args->{ recipient_array } ) eq 'ARRAY') {
	my $map = $self->_alloc_recipients_array_on_memory($args);
	push(@maps, $map);
    }


  MAP:
    for my $map ( @maps ) {
	# uniq $map
	next if $used_map{ $map }; $used_map{ $map } = 1;

	# try to open $map
	eval q{
	    use IO::MapAdapter;
	    my $obj = new IO::MapAdapter $map;
	    if (defined $obj) { 
		$obj->open || croak("cannot open $map");
	    }
	};
	if ($@) {
	    Log("Error: cannot open and ignore $map");
	    next MAP;
	}
	
	$self->_set_target_map($map);
	$self->_set_map_status($map, 'not done');
	$self->_set_map_position($map, 0);

	# To avoid infinite loop, we enforce some artificial limit.
	# The loop evaluation is limited to "4 * $number_of_mta" for each $map.
	my $loop_count     = 0;
	my $max_loop_count = ($#mta * 4) || 4;

      MTA_RETRY_LOOP:
	while (1) {
	    my $n_mta = 0;

	    # check infinite loop
	    if ($loop_count++ > $max_loop_count) {
		Log("Error: infinite loop for map=$map");
		last MTA_RETRY_LOOP;
	    }

	  MTA:
	    for my $mta (@mta) {
		# uniq $mta
		next if $used_mta{ $mta }; $used_mta{ $mta } = 1;

		# count the number of effective mta in this inter loop.
		$n_mta++;

		# o.k. try to deliver mail by using $mta.
		Log("(debug) use $mta for map=$map");
		$args->{ _mta } = $mta;
		$self->_deliver($args);

		# remove error messages for the next _deliver() session.
		$self->error_reset;

		# we read the whole $map now. 
		if ($self->_get_map_status($map) eq 'done') {
		    last MTA;
		}
	    } # end of MTA: loop

	    # end of MTA_RETRY_LOOP: loop
	    if ($self->_get_map_status($map) eq 'done') {
		last MTA_RETRY_LOOP;
	    }

	    # NO effective mta in this inter loop. It impiles that
	    # we used all MTA candidates. We reuse @mta again.
	    if ($n_mta == 0) { 
		Log("(debug) we used all MTA candidates. reuse \$mta");
		undef %used_mta;
		next MTA_RETRY_LOOP;
	    }
	}
    }

    # clean up recipient_map information after "all delivery"
    # CAUTION: this mapinfo tracks the delivery status.
    $self->_reset_mapinfo;

    if ( $self->{ _num_recipients } ) { 
	Log( "recipients: ". $self->{ _num_recipients } );
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
#    Arguments: $self $args
# Side Effects: remove error messages when we return from here
#               for the next _deliver() session.
# Return Value: none
sub _deliver
{
    my ($self, $args) = @_;

    $self->_initialize_delivery_session($args);

    # prepare smtp information
    my $myhostname = $args->{ myhostname } || 'localhost';
    
    # 0. create BSD SOCKET as the communication terminal
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    my $socket = $self->_connect($args);
    $socket || return;

    # 1. receive the first "220 .." message
    #    If you faces some error in this stage, you have to do nothing 
    #    since smtp connection has not established yet.
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_read_reply;
    if ($self->error) { return;}

    # 2. EHLO/HELO;
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_send_command("EHLO $myhostname");
    $self->_read_reply;
    if ($self->error) { $self->_reset_smtp_transaction;	return;}

    # 3. MAIL FROM;
    #    IF_ERROR_FOUND: do nothing and return as soon as possible
    $self->_send_mail_from($args);
    if ($self->error) { $self->_reset_smtp_transaction; return;}

    # 4. RCPT TO; ... send list of recipients
    #    IF_ERROR_FOUND: roll back the process to the state before this 
    $self->_send_recipient_list($args);
    if ($self->error) {
	$self->_rollback_map_position;
	$self->_reset_smtp_transaction;
	return;
    }

    # 5. DATA; send the mail body itself
    #    IF_ERROR_FOUND: handled in _send_data_to_mta(), so
    #                    return as soon as possible from here.
    $self->_send_data_to_mta($args);
    if ($self->error) { return;}

    # 6. QUIT; SMTP session closing ...
    #    IF_ERROR_FOUND: do nothing ?
    $self->_send_command("QUIT");
    $self->_read_reply;
    if ($self->error) { $self->_reset_smtp_transaction; return;}
}


# Descriptions: initialize _deliver() process
#               this routine is called at the first phase in _deliver()
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _initialize_delivery_session
{
    my ($self, $args) = @_;
    $self->{ _last_command } = '';
    $self->{ _status_code  } = '';
}


############################################################
#####
##### MAIL FROM:
#####

# Descriptions: send SMTP command "MAIL FROM"
#    Arguments: $self $args
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
#               IO::MapAdapter class is essential to handle abstract 
#               $recipient_map.
#    Arguments: $self $args
# Side Effects: $self->{ _retry_recipient_table } has recipients which 
#               causes some errors.
#               _{set,get}_map_position() and _{set,get}_map_status()
#               tracks the delivery process.
# Return Value: none
sub _send_recipient_list_by_recipient_map
{
    my ($self, $args) = @_;
    my $map = $self->_get_target_map;

    # open abstract recipient list objects.
    # $map syntax is "type:parameter", e.g., 
    # file:$filename mysql:$schema_name
    use IO::MapAdapter;
    my $obj = new IO::MapAdapter $map;

    unless (defined $obj) {
	Log("Error: cannot get object for $map by IO::MapAdapter");
    }
    else { # $obj is good.
	my $rcpt;
	my $num_recipients = 0;
	my $recipient_limit = $self->{_recipient_limit};

	$obj->open || do {
	    $self->_error_why( $obj->error );
	    return undef;
	};

	# roll back the previous file offset
	if ($self->_get_map_position($map) > 0) {
	    $obj->setpos( $self->_get_map_position($map) );
	}

	# XXX $obj->get_recipient returns a mail address.
      RCPT_INPUT:
	while (defined ($rcpt = $obj->get_recipient)) {
	    $num_recipients++;
	    $self->_send_command("RCPT TO:<$rcpt>");
	    $self->_read_reply;

	    # save addresses to retry later.
	    if ($self->{_error_action} eq 'retry') {
		$self->{ _retry_recipient_table }->{ $rcpt } = 'retry';
	    }

	    last RCPT_INPUT if $num_recipients >= $recipient_limit;
	}

	# save the current position in the file handle
	$self->_set_map_position($map, $obj->getpos);

	# done.
	if ($obj->eof) {
	    $self->_set_map_status($map, 'done');
	}

	# ends
	$obj->close;

	# count up the total number of recipients
	$self->{ _num_recipients } += $num_recipients;

	unless ($num_recipients) {
	    Log("Error: no recipients for $map");
	    $self->_send_command("RSET");
	    $self->_read_reply;
	}
    }
}


# Descriptions: send "RCPT TO:<recipient>" to MTA
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub _send_recipient_list
{
    my ($self, $args) = @_;
    
    # evaluate recipient_maps
    if ( $self->_get_target_map ) {
	$self->_send_recipient_list_by_recipient_map($args);
    }
}


# Descriptions: create CODE REFERECE to handle recipients array on memory 
#    Arguments: $self $args
# Side Effects: $me is referenced, so not destroyed. It is a closure (?).
# Return Value: CODE REFERENCE
sub _alloc_recipients_array_on_memory
{
    my ($self, $args) = @_;
    return sub {
	my ($me) = @_;
	$me->{ _recipients_array_on_memory } = $args->{ recipient_array };
    };
}


############################################################
#####
##### DATA:
#####

# Descriptions: send the header part of the message to socket
#    Arguments: $self $socket $ref_to_header
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
#    Arguments: $self $socket "Netlib::Messages object"
# Side Effects: none
# Return Value: none
sub _send_body_to_mta
{
    my ($self, $socket, $msg) = @_;

    # XXX $msg is Netlib::Messages object.
    $msg->set_log_function( $SmtpLogFunctionPointer );
    $msg->print($socket);
}


# Descriptions: send message itself to file handle (BSD socket here)
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
#         TODO: MIME/multipart
sub _send_data_to_mta
{
    my ($self, $args) = @_;

    # prepare smtp information
    my $body       = $args->{ body };
    my $header     = $args->{ header };
    my $socket     = $self->{'_socket'};

    if (defined $body) {
	$self->_send_command("DATA");
	$self->_read_reply;

	# XXX if "DATA" transaction cannot start, retry ?
	if ($self->_get_status_code != '354' || $self->error) { 
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
	$self->_send_command(".");
	$self->_read_reply;
    }
}


############################################################
#####
##### QUIT / RSET
#####

# Descriptions: send the SMTP reset "RSET" command
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub _reset_smtp_transaction
{
    my ($self, $args) = @_;
    $self->_send_command("RSET");
    $self->_read_reply;
    Log("Info: reset smtp transcation");
}



=head1 SEE ALSO

L<IO::Socket>
L<Netlib::Utils>
L<Netlib::INET4>
L<Netlib::INET6>


=head1 AUTHOR

Ken'ichi Fukamachi


=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Netlib::SMTP.pm appeared in fml5.

=cut

1;
