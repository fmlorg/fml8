#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: gen_table.pl,v 1.2 2002/04/01 23:41:23 fukachan Exp $
#

use strict;
use Carp;
use FileHandle;
use File::Basename;

print "<UL>\n";

for my $f (@ARGV) {
    my $fn = basename($f);
    print "\t<LI><A HREF=\"$f\">$fn</A>\n\n";

    my $fh = new FileHandle $f;
    my $p = 0;

  IN:
    while (<$fh>) {
	next if /^\s*$/;
	last if $_;
    }

  IN:
    while (<$fh>) {
	$p++ if /^\s*$/;

	print $_ if $p == 2;
	last IN if $p > 2;
    }

    print "\n";
}

print "</UL>\n";

exit 0;
