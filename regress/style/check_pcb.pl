#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use FileHandle;

my $wh     = new FileHandle "|rev|sort|rev";
my $fn     = '';
my $format = "%25s %25s %3s %s\n";

$| = 1;

printf $format, "module", "function", "", "category";
printf $format, "", "", "<--", "(get value)";
printf $format, "", "", "-->", "(set value)";
print "-" x 80;
print "\n";

while (<>) {
    if (/^sub (\S+)/) {
	$fn = $1;
    }

    if (/pcb->set\("(\S+)",/) {
	printf $wh $format, cleanup($ARGV), $fn, "-->", $1;
    }

    if (/pcb->get\("(\S+)",/) {
	printf $wh $format, cleanup($ARGV), $fn, "<--", $1;
    }
}

exit 0;

sub cleanup
{
    my ($s) = @_;

    $s =~ s@.pm$@@;
    $s =~ s@//@/@g;

    return $s;
}
