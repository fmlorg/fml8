#!/usr/bin/env perl
#
# $FML: check_pcb.pl,v 1.3 2004/03/14 07:04:47 fukachan Exp $
#

use strict;
use Carp;
use FileHandle;

my $wh     = \*STDOUT; # new FileHandle " | rev | sort +2 | rev ";
my $fn     = '';
my $format = "%-10s %-40s %3s %s\n";

$| = 1;

printf $format, "module", "function", "", "category";
printf $format, "", "", "<--", "(get value)";
printf $format, "", "", "-->", "(set value)";
print "-" x 80;
print "\n";

while (<>) {
    if (/^sub\s+(\S+)/) {
	$fn = $1;
    }
    elsif (/^\}/) {
	$fn = '';
    }

    if ($fn) {
	if (/\$pcb->set\("(\S+)",/) {
	    printf $wh $format, cleanup($ARGV), $fn, "-->", $1;
	}

	if (/\$pcb->get\("(\S+)",/) {
	    printf $wh $format, cleanup($ARGV), $fn, "<--", $1;
	}
    }
}

exit 0;

sub cleanup
{
    my ($s) = @_;

    $s =~ s@.pm$@@;
    $s =~ s@//@/@g;
    $s =~ s@FML/Process/@@g;

    return $s;
}
