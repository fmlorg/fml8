#!/usr/bin/env perl
#
# $FML$
#

use strict;

my $in_sub    = 0;
my $in_head   = 0;
my $defined   = 0;
my $close     = 0;
my $count     =  0;
my $buf       = '';
my $prev_argv = '';
my $prev_line = '';

while (<>) {
    # reset the line number counter
    if ($prev_argv ne $ARGV) {
	$count     = 0;
	$prev_argv = $ARGV;
    }
    $count++;

    if (/^\s*\#/ || /^\s*$/) {
	$prev_line = $_;
	next;
    }

    # ignore documents
    if (/^\=\w+/) {
	$prev_line = $_;
	$in_head = 1;
	$in_head = 0 if /^\=cut/;
	next;
    }
    if ($in_head) {
	$prev_line = $_;
	next;
    }

    # 
    # 1. check the usage of open() and close() under not check of defined()
    # 
    if (/defined/) { $defined = 1;}
    if (/\$\S+\-\>(close|open)/ && (!/^sub /) && (!/^=head/) && (!/\$self/)) {
	unless ($defined) {
	    $buf .= " ===> ". $_;
	    print "<<<($ARGV $count)\n", $buf, "\n>>>\n\n";
	}
    }


    # 
    # 2. check FNF
    # 
    if (/^sub / && ($prev_line !~ /^\#/)) {
	print "$ARGV $count (FNF)> $_";
    }

    # 
    # last resort: logging buffer
    # 
    if (/^sub |^\}/) {
	undef $buf;
	$in_sub  = 1;
	$defined = 0;
    }

    if ($in_sub) {
	$buf .= $_;
    }

    $prev_line = $_;
}
