#!/usr/bin/perl

print "1..1\n";

BEGIN {
	$^O = '';
}

use File::Spec::Functions;


if (catfile('a','b','c') eq 'a/b/c') {
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

