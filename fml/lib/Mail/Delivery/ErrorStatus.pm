#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ErrorStatus.pm,v 1.3 2002/06/01 03:29:10 fukachan Exp $
#

package Mail::Delivery::ErrorStatus;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(errstr error error_set error_clear);

=head1 NAME

Mail::Delivery::ErrorStatus - error handling component

=head1 SYNOPSIS

Use this module in your C<Something> class module like this:

   package Something;
   use Mail::Delivery::ErrorStatus qw(errstr error error_set error_clear);

   sub xxx
   {
      if something errors ...
      $self->error_set( why this error occurs ... );
   }

You use C<Something> module like this.

   use Something;
   $obj = new Something;
   $obj->xxx();
   unless ($obj->error) { $obj->do_somting( ...); };

=head1 DESCRIPTION

simple utility functions to manipulate error messages.

=head1 METHODS

=head2 C<error_set($message)>

save $message as an error message.

=head2 C<error()>

return $message which is saved by C<error_set($msg)>.

=cut


# Descriptions: set the error message
#    Arguments: OBJ($self) STR($mesg)
# Side Effects: update OBJ
# Return Value: STR
sub error_set
{
    my ($self, $mesg) = @_;
    $self->{'_error_reason'} = $mesg;
}


# Descriptions: get the error message
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub error
{
    my ($self) = @_;
    return $self->{'_error_reason'};
}


# Descriptions: get the error message
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub errstr
{
    my ($self) = @_;
    return $self->{'_error_reason'};
}


# Descriptions: clear the error message
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub error_clear
{
    my ($self) = @_;
    my $msg = $self->{'_error_reason'};
    undef $self->{'_error_reason'} if defined $self->{'_error_reason'};
    undef $self->{'_error_action'} if defined $self->{'_error_action'};
    return $msg;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::ErrorStatus first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
