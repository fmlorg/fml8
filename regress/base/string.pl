#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: string.pl,v 1.4 2001/06/17 09:00:30 fukachan Exp $
#

use strict;
use lib qw(./lib/ ../../cpan/lib);
use FML::Language::ISO2022JP qw(STR2EUC);

my $debug = defined $ENV{'debug'} ? 1 : 0;

for (@ARGV) {
    my $x = &STR2EUC($_);
    print "<$_> -> <$x>\n";
}

exit 0;
