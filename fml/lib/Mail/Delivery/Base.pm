#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package Mail::Delivery::Base;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Delivery::Base - delivery system base class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 SOCKET HANDLING

=head2 set_socket($socket)

=head2 get_socket()

=cut


# Descriptions: save socket handle.
#    Arguments: OBJ($self) HANDLE($socket)
# Side Effects: update $self.
# Return Value: none
sub set_socket
{
    my ($self, $socket) = @_;

    $self->{ _socket } = $socket || undef;
}


# Descriptions: return current socket.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HANDLE
sub get_socket
{
    my ($self) = @_;

    return( $self->{ _socket } || undef );
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
	my $r = undef;
	eval q{
	    $r = getpeername($socket);
	};
	return( $@ ? 0 : $r );
    }

    return 0;
}


=head2 open()

dummy.

=head2 close()

close BSD socket

=cut


# Descriptions: dummy.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub open
{
    ;
}


# Descriptions: close BSD socket.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as close()
sub close
{
    my ($self) = @_;
    my $socket = $self->get_socket();

    if (defined $socket) {
	$socket->close;
    }
    else {
	$self->logerror("try to close invalid socket");
    }
}


=head1 LOG FUNCTION

=head2 log($buf)

log interface (info level).

=head2 logerror($buf)

log interface (error level).

=cut


# Descriptions: log interface (informational level).
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: none
sub log
{
    my ($self, $buf) = @_;
    my $fp = $self->get_log_info_function();

    if (defined $fp) {
	eval q{ &$fp($buf);};
	if ($@) {
	    carp($@);
	}
    }
}


# Descriptions: log interface (error level).
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: none
sub logerror
{
    my ($self, $buf) = @_;
    my $fp = $self->get_log_error_function() || $self->get_log_info_function();

    if (defined $fp) {
	eval q{ &$fp($buf);};
	if ($@) {
	    carp($@);
	}
    }
}


# Descriptions: log interface (debug level).
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: none
sub logdebug
{
    my ($self, $buf) = @_;
    my $fp = $self->get_log_debug_function() || $self->get_log_info_function();

    if (defined $fp) {
	eval q{ &$fp($buf);};
	if ($@) {
	    carp($@);
	}
    }
}


=head2 get_log_function()

get log function (defined for compatibility).

=head2 set_log_function($fp)

set log function (defined for compatibility).

=cut


# Descriptions: set log function pointer (defined for compatibility).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_log_function
{
    my ($self) = @_;
    $self->get_log_info_function();
}


# Descriptions: return log function pointer (defined for compatibility).
#    Arguments: OBJ($self) CODE($fp)
# Side Effects: update $self.
# Return Value: CODE
sub set_log_function
{
    my ($self, $fp) = @_;
    $self->set_log_info_function($fp);
}


=head2 get_log_info_function()

get log function.

=head2 set_log_info_function($fp)

set log function.

=cut


# Descriptions: return log function pointer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_log_info_function
{
    my ($self) = @_;

    return( $self->{ _log_info_function } || undef );
}


# Descriptions: return log function pointer.
#    Arguments: OBJ($self) CODE($fp)
# Side Effects: update $self.
# Return Value: CODE
sub set_log_info_function
{
    my ($self, $fp) = @_;

    $self->{ _log_info_function } = $fp || undef;
}


=head2 get_log_error_function()

get log function.

=head2 set_log_error_function($fp)

set log function.

=cut


# Descriptions: return log function pointer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_log_error_function
{
    my ($self) = @_;

    return( $self->{ _log_error_function } || undef );
}


# Descriptions: return log function pointer.
#    Arguments: OBJ($self) CODE($fp)
# Side Effects: update $self.
# Return Value: CODE
sub set_log_error_function
{
    my ($self, $fp) = @_;

    $self->{ _log_error_function } = $fp || undef;
}


=head2 get_log_debug_function()

get log function.

=head2 set_log_debug_function($fp)

set log function.

=cut


# Descriptions: return log function pointer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_log_debug_function
{
    my ($self) = @_;

    return( $self->{ _log_debug_function } || undef );
}


# Descriptions: return log function pointer.
#    Arguments: OBJ($self) CODE($fp)
# Side Effects: update $self.
# Return Value: CODE
sub set_log_debug_function
{
    my ($self, $fp) = @_;

    $self->{ _log_debug_function } = $fp || undef;
}


=head1 SMTP TRANSACTION LOG

=head2 smtplog($buf)

smtp transaction log.

=cut


# Descriptions: smtp transaction log interface.
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: none
sub smtplog
{
    my ($self, $buf) = @_;
    my $fp = $self->get_smtp_log_function();
    my $wh = $self->get_smtp_log_handle();

    if (defined $wh) {
	print $wh $buf;
    }
    elsif (defined $fp) {
	eval q{ &$fp($buf);};
	if ($@) {
	    carp($@);
	}
    }
}


=head2 get_smtp_log_function()

get smtp log function.

=head2 set_smtp_log_function($fp)

set smtp log function.

=cut


# Descriptions: return smtp log function pointer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_smtp_log_function
{
    my ($self) = @_;

    return( $self->{ _smtp_log_function } || undef );
}


# Descriptions: return smtp log function pointer.
#    Arguments: OBJ($self) CODE($fp)
# Side Effects: update $self.
# Return Value: CODE
sub set_smtp_log_function
{
    my ($self, $fp) = @_;

    $self->{ _smtp_log_function } = $fp || undef;
}


=head2 get_smtp_log_handle()

get smtp log handle.

=head2 set_smtp_log_handle($fp)

set smtp log handle.

=cut


# Descriptions: return smtp log handle pointer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_smtp_log_handle
{
    my ($self) = @_;

    return( $self->{ _smtp_log_handle } || undef );
}


# Descriptions: return smtp log handle pointer.
#    Arguments: OBJ($self) HANDLE($fp)
# Side Effects: update $self.
# Return Value: HANDLE
sub set_smtp_log_handle
{
    my ($self, $fp) = @_;

    $self->{ _smtp_log_handle } = $fp || undef;
}


=head1 ERROR MESSAGE HANDLING

=head2 set_error($msg)

set the error message.

=head2 get_error()

get the error message.

=head2 clear_error().

clear the error message.

=cut


# Descriptions: set the error message.
#    Arguments: OBJ($self) STR($mesg)
# Side Effects: update OBJ
# Return Value: STR
sub set_error
{
    my ($self, $mesg) = @_;
    $self->{'_error_reason'} = $mesg || '';
}


# Descriptions: get the error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_error
{
    my ($self) = @_;
    return( $self->{'_error_reason'} || '' );
}


# Descriptions: clear the error message. return the last error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub clear_error
{
    my ($self) = @_;
    my $msg = $self->{'_error_reason'};
    undef $self->{'_error_reason'} if defined $self->{'_error_reason'};
    undef $self->{'_error_action'} if defined $self->{'_error_action'};
    return $msg;
}


=head1 COMPATIBLE ERROR MESSAGE HANDLING

=head2 error()

same as get_error().

=head2 errstr()

same as get_error().

=cut


# Descriptions: get the error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub error
{
    my ($self) = @_;
    $self->get_error();
}


# Descriptions: get the error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub errstr
{
    my ($self) = @_;
    $self->get_error();
}


=head1 SMTP TRANSACTION

=cut


# Descriptions: save smtp sender info.
#    Arguments: OBJ($self) STR($command)
# Side Effects: update $self
# Return Value: none
sub set_smtp_sender
{
    my ($self, $command) = @_;

    $self->{ _smtp_sender } = $command;
}


# Descriptions: get smtp sender info.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_smtp_sender
{
    my ($self) = @_;

    return( $self->{ _smtp_sender } || '' );
}


# Descriptions: set smtp_recipient_limit.
#    Arguments: OBJ($self) NUM($limit)
# Side Effects: update $self
# Return Value: none
sub set_smtp_recipient_limit
{
    my ($self, $limit) = @_;

    $self->{ _smtp_recipient_limit } = $limit || 1000;

    if ($limit != 1000) {
	$self->logdebug("smtp_recipient_limit = $limit");
    }
}


# Descriptions: get smtp_recipient_limit.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_smtp_recipient_limit
{
    my ($self) = @_;

    return( $self->{ _smtp_recipient_limit } || '' );
}


# Descriptions: set smtp_default_timeout.
#    Arguments: OBJ($self) NUM($timeout)
# Side Effects: update $self
# Return Value: none
sub set_smtp_default_timeout
{
    my ($self, $timeout) = @_;

    $self->{ _smtp_default_timeout } = $timeout || 10;
}


# Descriptions: get smtp_default_timeout.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_smtp_default_timeout
{
    my ($self) = @_;

    return( $self->{ _smtp_default_timeout } || 10 );
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


#################################################################
#####
##### status codes manipulations
#####

=head2 set_status_code($value)

save C<($value)> as status code.

=head2 get_status_code()

get the latest status code.

=cut


# XXX-TODO: private method _function() MUST NOT over modules.


# Descriptions: get current status code.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_status_code
{
    my ($self) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    return( $self->{'_status_code'} || '' );
}


# Descriptions: set current status code.
#    Arguments: OBJ($self) STR($value)
# Side Effects: update object
# Return Value: STR
sub set_status_code
{
    my ($self, $value) = @_;

    $self->{'_status_code'} = $value || '';
}




#################################################################
#####
##### utility to control $recipient_map
#####

=head1 METHODS TO HANDLE POSITION at IO MAP

=head2 set_target_map($map)

save the current C<map> name
where C<map> is a name usable at C<recipient_maps>

=head2 get_target_map()

return the current C<map>
where C<map> is a name usable at C<recipient_maps>

=cut


# Descriptions: set target map.
#    Arguments: OBJ($self) STR($map)
# Side Effects: update object
# Return Value: STR
sub set_target_map
{
    my ($self, $map) = @_;

    $self->{ _mapinfo }->{ _curmap } = $map || '';
}


# Descriptions: get current target map.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_target_map
{
    my ($self) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    return( $self->{ _mapinfo }->{ _curmap } || '' );
}


=head2 set_map_status($map, $status)

save C<$status> for C<$map> IO.
For example, C<$status> is 'not done'.

=head2 get_map_status($map)

get the current C<$status> for C<$map> IO.

=cut


# Descriptions: set map status.
#    Arguments: OBJ($self) STR($map) STR($status)
# Side Effects: update object
# Return Value: STR
sub set_map_status
{
    my ($self, $map, $status) = @_;
    $self->{ _mapinfo }->{ $map }->{prev_status} =
	$self->{ _mapinfo }->{ $map }->{status} || 'not done';
    $self->{ _mapinfo }->{ $map }->{status}      = $status;
}


# Descriptions: get map status.
#    Arguments: OBJ($self) STR($map)
# Side Effects: update object
# Return Value: STR
sub get_map_status
{
    my ($self, $map) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{ _mapinfo }->{ $map }->{status} || '';
}


=head2 set_mta_status($mta, $status)

save C<$status> for C<$mta>.

=head2 get_mta_status($mta)

get the current C<$status> for C<$mta>.

=cut


# Descriptions: set mta status.
#    Arguments: OBJ($self) STR($mta) STR($status)
# Side Effects: update object
# Return Value: STR
sub set_mta_status
{
    my ($self, $mta, $status) = @_;
    $self->{ _mtainfo }->{ $mta }->{prev_status} =
	$self->{ _mtainfo }->{ $mta }->{status} || 'unknown';
    $self->{ _mtainfo }->{ $mta }->{status}      = $status;
}


# Descriptions: get mta status.
#    Arguments: OBJ($self) STR($mta)
# Side Effects: update object
# Return Value: STR
sub get_mta_status
{
    my ($self, $mta) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{ _mtainfo }->{ $mta }->{status} || '';
}


=head2 set_map_position($map, $position)

save the C<$position> for C<$map> IO.

=head2 get_map_position($map)

get the current C<$position> for C<$map> IO.

=cut


# Descriptions: set map position.
#    Arguments: OBJ($self) STR($map) STR($position)
# Side Effects: update object
# Return Value: STR
sub set_map_position
{
    my ($self, $map, $position) = @_;
    $self->{ _mapinfo }->{ $map }->{prev_position} =
	$self->{ _mapinfo }->{ $map }->{position} || 0;
    $self->{ _mapinfo }->{ $map }->{position}   = $position;
}


# Descriptions: get map position.
#    Arguments: OBJ($self) STR($map)
# Side Effects: update object
# Return Value: NUM
sub get_map_position
{
    my ($self, $map) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{ _mapinfo }->{ $map }->{position} || 0;
}


=head2 rollback_map_position()

stop the IO for the current C<$map>.
This method rolls back the operation state to the time when the
current IO for C<$map> begins.

=cut


# Descriptions: rollback IO for current map back to the starting position.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub rollback_map_position
{
    my ($self) = @_;
    my $map    = $self->get_target_map;

    # count the number of rollback to avoid infinite loop
    if (($self->{ _map_rollback_info }->{ $map }->{ count } || 0) > 2) {
	$self->log("Error: not rollback $map to avoid infinite loop");
	return ;
    }
    else {
	$self->{ _map_rollback_info }->{ $map }->{ count }++;
    }

    my $prev_pos = $self->{ _mapinfo }->{ $map }->{prev_position};
    my $pos      = $self->{ _mapinfo }->{ $map }->{position};
    $self->set_map_position($map, $prev_pos);
    $self->log("Info: rollback $map from $pos to $prev_pos");

    my $prev_status = $self->{ _mapinfo }->{ $map }->{prev_status};
    my $status      = $self->{ _mapinfo }->{ $map }->{status};
    $self->set_map_status($map, $prev_status);
    $self->log("Info: rollback status of $map to '$prev_status'");
}


=head2 clear_mapinfo()

clear information around the latest map operation.

=cut


# Descriptions: reset info for the current map.
#    Arguments: OBJ($self)
# Side Effects: clear info in object
# Return Value: none
sub clear_mapinfo
{
    my ($self) = @_;
    $self->set_target_map('');
    delete $self->{ _mapinfo };
    delete $self->{ _map_rollback_info };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Base appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
