#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::File;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $ErrorString);
use Carp;


require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(mkdirhier touch);

=head1 NAME

FML::File.pm - error handling utilities

=head1 SYNOPSIS

   use FML::File qw(mkdiehier);
   mkdirhier($dir, $mode);

=head1 DESCRIPTION

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::File.pm appeared in fml5.

=cut

sub error       { return $ErrorString;}

sub error_reset { undef $ErrorString;}

sub mkdirhier
{
    my ($dir, $mode) = @_;

    # XXX $mode (e.g. 0755) should be a numeric not a string
    eval qq{ 
	use File::Path;
	mkpath(\$dir, 0, $mode);
    };
    $ErrorString = $@;
}


sub touch
{
    my ($file, $mode) = @_;
}


1;
