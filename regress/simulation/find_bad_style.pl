#!/usr/bin/env perl
#
# $FML: find_bad_style.pl,v 1.1 2002/06/01 05:06:22 fukachan Exp $
#

use strict;

my $copyright = '';
my $in_sub    = 0;
my $in_head   = 0;
my $defined   = 0;
my $close     = 0;
my $count     =  0;
my $buf       = '';
my $prev_argv = '';
my $prev_line = '';

while (<>) {
    if (/^\#.*(Copyright.*)/i) {
	$copyright = $1;
    }

    if (/^\#.*\$FML:.*(\d{4})\/\d{2}\/\d{2} /i) {
	my $year = $1;
	print "\n$ARGV\n\tcopyright wrong\n" unless $copyright =~ /$year/;
    }

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
	    $buf =~ s/\n/\n\t/gm; $buf =~ s/^/\t/;
	    print "\n$ARGV $count {\n\tdefined() ?\n\n", $buf, "\n}\n\n";
	}
    }


    # 
    # 2. check FNF
    # 
    if (/^sub / && ($prev_line !~ /^\#\s*\w+/)) {
	print "\n$ARGV $count\n\t(FNF)> $_";
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
