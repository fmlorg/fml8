#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.12 2003/08/23 15:33:16 fukachan Exp $
#

package Mail::Delivery::Utils;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK
	    $LogFunctionPointer $SmtpLogFunctionPointer);
use Carp;
use Mail::Delivery::ErrorStatus qw(error_set error error_clear);

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
	     Log
	     _smtplog
	     smtplog

	     $LogFunctionPointer
	     $SmtpLogFunctionPointer

	     error_set
	     error
	     error_clear

	     _set_status_code
	     _get_status_code

	     _set_target_map
	     _get_target_map
	     _set_map_status
	     _set_map_position
	     _get_map_status
	     _get_map_position
	     _rollback_map_position
	     _reset_mapinfo
	     );


=head1 NAME

Mail::Delivery::utils - utility programs for mail delivery class

=head1 SYNOPSIS

For example,

   use Mail::Delivery::utils;
   Log( $message_to_log );

=head1 DESCRIPTION

several utility functions for C<Mail::Delivery> sub classes.

=cut

#################################################################
#####
##### General Logging
#####

=head1 LOGGING FUNCTIONS

=head2 Log($buf)

Logging interface.
send C<$buf> (the log message) to the function specified as
C<$LogFunctionPointer> (CODE REFERENCE).
C<$LogFunctionPointer> is expected to set up at
C<Mail::Delivery::Delivery::new()>
If it is not specified,
the logging message is forwarded to STDERR channel.

=cut


# XXX-TODO: we should provide both Log() and $delivery->log() methods ?


# Descriptions: log by specified function pointer or into STDERR
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: none
sub Log
{
    my ($buf) = @_;

    # function pointer to logging function
    my $fp = $LogFunctionPointer;

    # XXX valid use of STDERR ?
    if ($fp) {
	eval &$fp($buf);
	print STDERR $@, "\n" if $@;
    }
    else {
	print STDERR @_, "\n";
    }
}


#################################################################
#####
##### SMTP Logging
#####

=head2 smtplog($buf)

smtp logging interface as the same as C<Log()> but for smtp
transcation log.
If the real log function pointer is not specified at
C<Mail::Delivery::Delivery::new()>,
C<$buf> is sent to C<STDERR>.

=cut


# Descriptions: log by specified function pointer or into STDERR
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: none
sub smtplog
{
    my ($self, $buf) = @_;

    if (defined $buf) {
	if (defined $self->{ _smtp_log_handle }) {
	    my $wh = $self->{ _smtp_log_handle };
	    print $wh $buf;
	}
	else {
	    _smtplog($buf);
	}
    }
}


# Descriptions: log by specified function pointer or into STDERR
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: none
sub _smtplog
{
    my ($buf) = @_;

    # function pointer to logging function
    my $fp = $SmtpLogFunctionPointer;

    if ($fp) {
	eval &$fp($buf);
	print STDERR $@, "\n" if $@;
    }
    else {
	print STDERR @_, "\n";
    }
}



#################################################################

=head1 METHODS FOR ERROR MESSAGES AND STATUS CODES

=head2 error_set($mesg)

save C<$mesg>.

=head2 error()

return the latest error message which saved by C<error_set()>.

=head2 error_clear()

reset the error buffer which C<error_set()> and C<error()> use.

=cut


#################################################################
#####
##### status codes manipulations
#####

=head2 _set_status_code($value)

save C<($value)> as status code.

=head2 _get_status_code()

get the latest status code.

=cut


# Descriptions: get current status code
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub _get_status_code
{
    my ($self) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{'_status_code'};
}


# Descriptions: set current status code
#    Arguments: OBJ($self) STR($value)
# Side Effects: update object
# Return Value: STR
sub _set_status_code
{
    my ($self, $value) = @_;
    $self->{'_status_code'} = $value;
}




#################################################################
#####
##### utility to control $recipient_map
#####

=head1 METHODS TO HANDLE POSITION at IO MAP

=head2 _set_target_map($map)

save the current C<map> name
where C<map> is a name usable at C<recipient_maps>

=head2 _get_target_map()

return the current C<map>
where C<map> is a name usable at C<recipient_maps>

=cut


# Descriptions: set target map
#    Arguments: OBJ($self) STR($map)
# Side Effects: update object
# Return Value: STR
sub _set_target_map
{
    my ($self, $map) = @_;
    $self->{ _mapinfo }->{ _curmap } = $map;
}


# Descriptions: get current target map
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub _get_target_map
{
    my ($self) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{ _mapinfo }->{ _curmap };
}


=head2 _set_map_status($map, $status)

save C<$status> for C<$map> IO.
For example, C<$status> is 'not done'.

=head2 _set_map_position($map, $position)

save the C<$position> for C<$map> IO.

=head2 _get_map_status($map)

get the current C<$status> for C<$map> IO.

=head2 _get_map_position($map)

get the current C<$position> for C<$map> IO.

=cut


# Descriptions: set map status
#    Arguments: OBJ($self) STR($map) STR($status)
# Side Effects: update object
# Return Value: STR
sub _set_map_status
{
    my ($self, $map, $status) = @_;
    $self->{ _mapinfo }->{ $map }->{prev_status} =
	$self->{ _mapinfo }->{ $map }->{status} || 'not done';
    $self->{ _mapinfo }->{ $map }->{status}      = $status;
}


# Descriptions: set map position
#    Arguments: OBJ($self) STR($map) STR($position)
# Side Effects: update object
# Return Value: STR
sub _set_map_position
{
    my ($self, $map, $position) = @_;
    $self->{ _mapinfo }->{ $map }->{prev_position} =
	$self->{ _mapinfo }->{ $map }->{position} || 0;
    $self->{ _mapinfo }->{ $map }->{position}   = $position;
}


# Descriptions: get map status
#    Arguments: OBJ($self) STR($map)
# Side Effects: update object
# Return Value: STR
sub _get_map_status
{
    my ($self, $map) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{ _mapinfo }->{ $map }->{status};
}


# Descriptions: get map position
#    Arguments: OBJ($self) STR($map)
# Side Effects: update object
# Return Value: STR
sub _get_map_position
{
    my ($self, $map) = @_;

    # XXX-TODO: return what code if undefined ?
    # XXX-TODO: consider Principle of Least Surprise!
    $self->{ _mapinfo }->{ $map }->{position};
}


=head2 _rollback_map_position()

stop the IO for the current C<$map>.
This method rolls back the operation state to the time when the
current IO for C<$map> begins.

=head2 _reset_mapinfo()

clear information around the latest map operation.

=cut


# Descriptions: rollback IO for current map
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _rollback_map_position
{
    my ($self) = @_;
    my $map    = $self->_get_target_map;

    # count the number of rollback to avoid infinite loop
    if ( $self->{ _map_rollback_info }->{ $map }->{ count } > 2 ) {
	Log("Error: not rollback $map to avoid infinite loop");
	return ;
    }
    else {
	$self->{ _map_rollback_info }->{ $map }->{ count }++;
    }

    my $prev_pos = $self->{ _mapinfo }->{ $map }->{prev_position};
    my $pos      = $self->{ _mapinfo }->{ $map }->{position};
    $self->_set_map_position($map, $prev_pos);
    Log("Info: rollback $map from $pos to $prev_pos");

    my $prev_status = $self->{ _mapinfo }->{ $map }->{prev_status};
    my $status      = $self->{ _mapinfo }->{ $map }->{status};
    $self->_set_map_status($map, $prev_status);
    Log("Info: rollback status of $map to '$prev_status'");
}


# Descriptions: reset info for the current map
#    Arguments: OBJ($self)
# Side Effects: clear info in object
# Return Value: none
sub _reset_mapinfo
{
    my ($self) = @_;
    $self->_set_target_map('');
    delete $self->{ _mapinfo };
    delete $self->{ _map_rollback_info };
}



=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
