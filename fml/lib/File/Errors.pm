#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package File::Errors;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(error_reason error error_reset);

=head1 NAME

File::Errors - error handling utilities

=head1 SYNOPSIS

	package Something;
	use File::Errors qw(error_reason error error_reset);

	sub xxx
	{
		if something errors ...
		$self->error_reason( error reason );
	}

When you use Something module,

	use Something;
	$obj = new Something;
	unless ($obj->error) { $obj->do_somting( ...); };


=head1 METHODS

=head2 C<error_reason($message)>

save $message

=head2 C<error()>

return $message which is saved by C<error_reason($msg)>.

=cut


sub error_reason
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

File::Errors appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
