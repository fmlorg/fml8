#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Errors;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

use File::Errors qw(error_reason error error_reset);

require Exporter;
@ISA       = qw(File::Errors Exporter);
@EXPORT_OK = qw(error_reason error error_reset);

=head1 NAME

FML::Errors - error handling utilities

=head1 SYNOPSIS

Consider the following C<Something> module.

	package Something;
	use FML::Errors qw(error_reason error error_reset);

	sub xxx
	{
		if something errors ...
		$self->error_reason( error reason );
	}

When you use C<Something> module,

	use Something;
	$obj = new Something;
	unless ($obj->error) { $obj->do_somting( ...); };

=head1 DESCRIPTION

This is a wrapper to L<File::Errors>.
All requests are forwarded to C<File::Errors>.

=head1 SEE ALSO

L<File::Errors>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Errors appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
