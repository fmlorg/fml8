#!/usr/bin/env perl
#
# $FML$
#

use strict;
use FileHandle;


for my $file (@ARGV) {
    my $rh = new FileHandle $file;
    my $fh;
    my ($x, $y) = ();

    while (<$rh>) {
	if (/^(\S+):/ && $file eq 'kern') {
	    $x = 'kern';
	    $y = $1;
	    $fh = _open($fh, $x, $y);
	}
	elsif (/^(\w+)\.(\S+):/) {
	    ($x, $y) = ($1, $2);
	    $fh = _open($fh, $x, $y);
	}
	else {
	    s/^\t//;
	    if (defined $fh) {	
		$fh->print($_);
	    }
	}
    }
}


sub _open
{
    my ($fh, $x, $y) = @_;

    $fh->close if defined $fh;
    system "mkdir -p $x";

    $fh = new FileHandle "> $x/$y";
    if (defined $fh) { 
	print STDERR "$x/$y opened\n";
    }
    else {
	print STDERR "fail to open $x/$y\n";
    }

    return $fh;
}
