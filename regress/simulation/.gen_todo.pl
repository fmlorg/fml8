#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

my $function;
my $todo = {};
my $KEY  = "__FILE_GLOBAL__";

while (<>) {
    if (/^sub (\S+)/o) {
	$function = $1;
    }

    if (/^sub .*\}/o || /^\}/o) {
	$function = $KEY;
    }

    if (/(XXX-TODO:|XXX-TODO)\s*(.*)\s*$/o) {
	my ($xtodo) = $2;
	$todo->{ $ARGV }->{ $function } .= "\t". $xtodo . "\n";
    }
}


for my $file (sort keys %$todo) {
    my $hash = $todo->{ $file };

    $file =~ s@lib//@@g;
    printf "\n%s\n", $file;
    for my $k (keys %$hash) {
	if ($k eq $KEY) {
	    my $buf = $hash->{ $k };
	    $buf =~ s/\t/   /g;
	    print $buf;
	}
	else {
	    printf "   sub %s\n%s\n", $k, $hash->{ $k };
	}
    }
}

exit 0;
