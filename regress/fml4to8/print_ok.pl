#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

my $is_ok  = 0;
my $format = "%-3s %s\n";

LINE:
    while (<>) {
	if (/^\.ok/) { 
	    $is_ok = 1; 
	    next LINE;
	}

	if (/^\.if\s+(\S+)/) {
	    if ($is_ok) {
		printf $format, "OK", $1;
	    }
	    else {
		printf $format, "", $1;
	    }
	    $is_ok = 0;
	}
    }

exit 0;
