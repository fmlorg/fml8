#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Base::File;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $ErrorString);
use Carp;


require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(mkdirhier touch);

=head1 NAME

FML::Base::Errors.pm - error handling utilities

=head1 SYNOPSIS

	package Something;
	use FML::Base::Errors qw(error_reason error error_reset);

	sub xxx
	{
		if something errors ...
		$self->error_reason( error reason );
	}

When you use Something module,

	use Something;
	$obj = new Something;
	unless ($obj->error) { $obj->do_somting( ...); };


=head1 DESCRIPTION

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Base::Errors.pm appeared in fml5.

=cut

sub error       { return $ErrorString;}
sub error_reset { undef $ErrorString;}

sub mkdirhier
{
    my ($dir, $mode) = @_;

    eval q{ 
	use File::Path;
	mkpath($dir, 0, $mode);
    };
    $ErrorString = $@;
}


sub touch
{

}


1;
