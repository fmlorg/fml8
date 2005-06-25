#!/usr/bin/env perl
#
# $FML: conv2sgml.pl,v 1.1.1.1 2004/04/02 04:39:48 fukachan Exp $
#

use strict;
use Carp;

my $i     = 0;
my $key   = '';
my $value = '';
my $table = {};

while (<>) {
    if (/^\s*$/o || /^\#/) {
	undef $key;
	next;
    }

    if (/^([Q48]):\s*(.*)/) {
	($key, $value) = ($1, $2);
	$i++ if $key eq 'Q';
	$table->{ $i }->{ $key } = $value;
	next;
    }

    if (/^\s+(.*)/) {
	$table->{ $i }->{ $key } .= "\n";
	$table->{ $i }->{ $key } .= $1;
    }
}

print "\n<!-- 注意!!! 自動生成されたファイル、手動編集禁止 !!! -->\n\n";

for my $i (sort {$a <=> $b} keys %$table) {
    print "<!-- $i -->\n";
    print "<row>\n";

    print "\n<entry>\n";
    print $table->{ $i }->{ Q };
    print "\n</entry>\n";

    print "\n<entry>\n";
    print $table->{ $i }->{ 4 };
    print "\n</entry>\n";

    print "\n<entry>\n";
    print $table->{ $i }->{ 8 };
    print "\n</entry>\n";

    print "\n</row>\n";
    print "\n";
}

exit 0;
