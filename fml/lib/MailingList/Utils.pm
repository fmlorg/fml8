#-*- perl -*-
#
#  Copyright (C) 2000-2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK 
	    $LogFunctionPointer $SmtpLogFunctionPointer);
use Carp;

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	     Log
	     _smtplog
	     smtplog

	     $LogFunctionPointer
	     $SmtpLogFunctionPointer

	     _error_reason
	     error 
	     error_reset 

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

MailingList::utils - utiliti programs for mail delivery

=head1 SYNOPSIS

For example,

   use MailingList::utils;
   Log( $message_to_log );

=head1 DESCRIPTION

=cut

#################################################################
#####
##### General Logging
#####

=head2

=item C<Log()>

Logging interface. 
If CODE REFERENCE is not specified at
MailingList::Delivery::new(), 
the logging message is forwarded to STDERR channel.

=cut


sub Log
{
    my ($buf) = @_;

    # function pointer to logging function
    my $fp = $LogFunctionPointer;

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
=head2

=item C<smtplog()>

smtp logging interface.
If CODE REFERENCE is not specified at
MailingList::Delivery::new(), 
the logging message is forwarded to STDERR channel.

=cut

sub smtplog
{
    my ($self, $buf) = @_;
    _smtplog($buf);
}

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
#####
##### error manipulations
#####
=head2

=item C<_error_reason()>

=item C<error()>

=item C<error_reset()>

=cut

sub _error_reason
{
    my ($self, $mesg) = @_;
    $self->{'_error_reason'} = $mesg;
}


sub error_reason
{
    my ($self, $mesg) = @_;
    $self->_error_reason($mesg);
}


sub error
{
    my ($self, $args) = @_;
    return $self->{'_error_reason'};
}


sub error_reset
{
    my ($self, $args) = @_;
    my $msg = $self->{'_error_reason'};
    undef $self->{'_error_reason'} if defined $self->{'_error_reason'};
    undef $self->{'_error_action'} if defined $self->{'_error_action'};
    return $msg;
}


#################################################################
#####
##### status codes manipulations
#####

=head2

=item C<_get_status_code()>

=item C<_set_status_code(value)>

=cut


sub _get_status_code
{
    my ($self) = @_;
    $self->{'_status_code'};
}


sub _set_status_code
{
    my ($self, $value) = @_;
    $self->{'_status_code'} = $value;
}




#################################################################
#####
##### utility to control $recipient_map
#####

=head2

=item	     C<_set_target_map()>

=item	     C<_get_target_map()>

=item	     C<_set_map_status()>

=item	     C<_set_map_position()>

=item	     C<_get_map_status()>

=item	     C<_get_map_position()>

=item	     C<_rollback_map_position()>

=item	     C<_reset_mapinfo()>

=cut

sub _set_target_map
{
    my ($self, $map) = @_;
    $self->{ _mapinfo }->{ _curmap } = $map;
}


sub _get_target_map
{
    my ($self) = @_;
    $self->{ _mapinfo }->{ _curmap };
}


sub _set_map_status
{
    my ($self, $map, $status) = @_;
    $self->{ _mapinfo }->{ $map }->{prev_status} = 
	$self->{ _mapinfo }->{ $map }->{status} || 'not done';
    $self->{ _mapinfo }->{ $map }->{status}      = $status;
}

sub _set_map_position
{
    my ($self, $map, $position) = @_;
    $self->{ _mapinfo }->{ $map }->{prev_position} = 
	$self->{ _mapinfo }->{ $map }->{position} || 0;
    $self->{ _mapinfo }->{ $map }->{position}   = $position;
}

sub _get_map_status
{
    my ($self, $map) = @_;
    $self->{ _mapinfo }->{ $map }->{status};
}

sub _get_map_position
{
    my ($self, $map) = @_;
    $self->{ _mapinfo }->{ $map }->{position};
}


sub _rollback_map_position
{
    my ($self) = @_;
    my $map      = $self->_get_target_map;

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


sub _reset_mapinfo
{
    my ($self) = @_;
    $self->_set_target_map('');
    delete $self->{ _mapinfo };
    delete $self->{ _map_rollback_info };
}



=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

MailingList::utils.pm appeared in fml5.

=cut

1;
