#!/usr/bin/env perl
#
# $FML: .gen_todo.pl,v 1.1 2003/01/11 16:10:03 fukachan Exp $
#

use strict;
use Carp;

my $function;
my $todo = {};
my $KEY  = "__FILE_GLOBAL__";
my $all  = 0;

while (<>) {
    if (/^sub (\S+)/o) {
	$function = $1;
    }

    if (/^sub .*\}/o || /^\}/o) {
	$function = $KEY;
    }

    next if /XXX-TODO.*curproc->util->/ && (! $all);

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
