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

use lib qw(./lib/ ../../cpan/lib);
use Dialect::ISO2022JP qw(STR2EUC);

for (@ARGV) {
    my $x = &STR2EUC($_);
    print "<$_> -> <$x>\n";
}

exit 0;
