#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package ErrorMessages::Status;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(error_set error error_reset);

=head1 NAME

ErrorMessages::Status - error handling component

=head1 SYNOPSIS

Use this module in your C<Something> class module like this:

   package Something;
   use ErrorMessages::Status qw(error_set error error_reset);

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


sub error_set
{
    my ($self, $mesg) = @_;
    $self->{'_error_reason'} = $mesg;
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


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

ErrorMessages::Status appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
