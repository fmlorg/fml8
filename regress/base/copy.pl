#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

use IO::File::Atomic;

($src, $dst) = @ARGV;
print "IO::File::Atomic->copy($src, $dst);\n";
print "sleep 3;\n";
sleep 3;
my $status = IO::File::Atomic->copy($src, $dst) || die("fail to copy");

exit 0;
