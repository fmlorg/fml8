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

print STDERR "specify STDIN\n";

my $body; while (<>) { $body .=  $_;}

use FML::Checksum;
$p = new FML::Checksum;
print $p->md5( \$body ), "\n";

exit 0;
