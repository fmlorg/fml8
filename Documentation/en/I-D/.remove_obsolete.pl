#!/usr/bin/env perl
#
# $FML: .remove_obsolete.pl,v 1.1 2001/08/22 22:24:37 fukachan Exp $
#

use strict;
use Carp;

print "cvs remove ";

my $prev = '';
for my $cur (sort <draft*txt>) {
    if (compare($prev, $cur)) {
	print "$prev ";
    }

    $prev = $cur;
}

print "\n";


sub compare
{
    my ($a, $b) = @_;
    my ($ta, $tb, $xa, $xb);

    if ($a =~ /(.*)\-\d+(\d)\.txt/) { $ta = $1; $xa = $2;}
    if ($b =~ /(.*)\-\d+(\d)\.txt/) { $tb = $1; $xb = $2;}

    return (($ta eq $tb) && ($xb - $xa) == 1) ? 1 : 0;
}
