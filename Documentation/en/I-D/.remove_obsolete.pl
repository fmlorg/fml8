#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

my $prev = '';
for my $cur (sort <draft*txt>) {
    if (compare($prev, $cur)) {
	print "cvs remove $prev\n";
    }

    $prev = $cur;
}


sub compare
{
    my ($a, $b) = @_;
    my ($ta, $tb, $xa, $xb);

    if ($a =~ /(.*)\-\d+(\d)\.txt/) { $ta = $1; $xa = $2;}
    if ($b =~ /(.*)\-\d+(\d)\.txt/) { $tb = $1; $xb = $2;}

    return (($ta eq $tb) && ($xb - $xa) == 1) ? 1 : 0;
}
