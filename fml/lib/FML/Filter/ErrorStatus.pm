#-*- perl -*-
#
#  Copyright (C) 2005,2007,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ErrorStatus.pm,v 1.2 2007/01/16 11:24:27 fukachan Exp $
#

package FML::Filter::ErrorStatus;

#
# XXX-TODO: we should not use FML::Filter::ErrorStatus module, is'nt it?
# XXX-TODO: FML/Config.pm
# XXX-TODO: FML/Credential.pm
# XXX-TODO: FML/Filter.pm
# XXX-TODO: FML/Filter/Header.pm
# XXX-TODO: FML/Filter/MimeComponent.pm
# XXX-TODO: FML/Filter/MimeComponent3.pm
# XXX-TODO: FML/Filter/TextPlain.pm
# XXX-TODO: File/Sequence.pm
# XXX-TODO: File/SimpleLock.pm
#


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(errstr error error_set error_clear);

=head1 NAME

FML::Filter::ErrorStatus - error handling component.

=head1 SYNOPSIS

Use this module in your C<Something> class module like this:

   package Something;
   use FML::Filter::ErrorStatus qw(errstr error error_set error_clear);

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

=head2 error_set($message)

save $message as an error message.

=head2 error()

return $message which is saved by C<error_set($msg)>.

=cut


# Descriptions: set the error message within $self object.
#    Arguments: OBJ($self) STR($mesg)
# Side Effects: update $self.
# Return Value: STR
sub error_set
{
    my ($self, $mesg) = @_;
    $self->{'_error_reason'} = $mesg if defined $mesg;
}


# Descriptions: get the error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub error
{
    my ($self) = @_;
    return $self->{'_error_reason'} ? $self->{'_error_reason'} : undef;
}


# Descriptions: get the error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub errstr
{
    my ($self) = @_;
    return $self->error();
}


# Descriptions: clear the error message buffer.
#    Arguments: OBJ($self)
# Side Effects: update $self.
# Return Value: STR (cleared message)
sub error_clear
{
    my ($self) = @_;
    my $msg = $self->{'_error_reason'};
    undef $self->{'_error_reason'} if defined $self->{'_error_reason'};
    undef $self->{'_error_action'} if defined $self->{'_error_action'};
    return $msg;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2007,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::ErrorStatus first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

FML::Filter::ErrorStatus is derived from ErrorStatus module in 2005.

=cut


1;
