#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

$| = 1;

my $in_curproc  = 0;
my $in_function = 0;
my $in_debug    = 0;
my $cur_function_name;

while (<>) {
    if (/^sub\s+(\S+)/) { 
	_reset();
	$in_function = 1;
	$cur_function_name = $1;
	next;
    }

    if (/if.*\$0 eq __FILE__/) {
	_reset();
    }

    if (/if \(0\) \{/) {
	_reset();
    }

    if ($in_function) {
	if (/if.*\$debug/) { 
	    $in_debug = 1;
	}
	elsif (/^\s*$/) { 
	    $in_debug = 0;
	}

	if (/print\s+STDERR/o) {
	    if ($in_debug) {
		print STDERR "ok $ARGV $cur_function_name\n" if 0;
	    }
	    else {
		print STDERR "?? $ARGV $cur_function_name $_";
	    }
	}
    }
}


sub _reset
{
    $in_curproc  = 0;
    $in_function = 0;
    $in_debug    = 0;
    undef $cur_function_name;
}
