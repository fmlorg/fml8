#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
#

use Carp;
use FML::BaseSystem;
use FML::IO::Map;


print STDERR "\n--- unix.group:wheel \n";
$mapobj = new FML::IO::Map 'unix.group:wheel';
$mapobj->open;
$line = 0;
while (defined ($_ = $mapobj->get_member)) { print $_, "\n";}
$mapobj->close;

print STDERR "\n--- /etc/motd \n";
$mapobj = new FML::IO::Map '/etc/motd';
$mapobj->open;
$line = 0;
while (defined ($_ = $mapobj->get_member)) { print $_, "\n";}
$mapobj->close;

print STDERR "\n--- file:/etc/motd \n";
$mapobj = new FML::IO::Map 'file:/etc/motd';
$mapobj->open;
$line = 0;
while (defined ($_ = $mapobj->get_member)) { print $_, "\n";}
$mapobj->close;

print STDERR "\n--- mysql:toymodel \n";
$mapobj = new FML::IO::Map 'mysql:toymodel';
$mapobj->dump_variables;
$mapobj->open;
$line = 0;
while (defined ($_ = $mapobj->get_member)) { print $_, "\n";}
$mapobj->close;



exit 0;



print STDERR "\n--- benchmark \n";
use Benchmark;
use FileHandle;


my $file = $ARGV[0] || "/usr/share/dict/web2";
my $lines = 0;
{
    $t2 = new Benchmark;
    $mapobj = new FML::IO::Map $file;
    $mapobj->open;
    $line = 0;
    while (defined ($_ = $mapobj->get_member)) { print $_;}
    $mapobj->close;

    $c = $mapobj->line_count;
    $t3 = new Benchmark;
    print STDERR timestr( timediff($t3, $t2) ), " for $c lines\n";
}

{
    $fh  = new FileHandle $file;
    $t0  = new Benchmark;
    my $c = 0;
    my $ec=0;
    if (defined $fh) {
	my $rcpt = '';
	while (<$fh>) { 
	    $c++;

	    chop;
	    print; 

	    next if /^\#/o;  # skip comment and off member
	    next if /^\s*$/o; # skip null line
	    next if /\s[ms]=/o;

	    # O.K. Checking delivery and addrs to skip;
	    ($rcpt) = split(/\s+/, $_);
	    $ec++;
	}
	$fh->close;
    }
    $t1 = new Benchmark;
    print STDERR timestr( timediff($t1, $t0) ), " for $ec/$c lines\n";
    $lines = $c;
}

$ra = timediff($t3, $t2);
$rb = timediff($t1, $t0);

print STDERR $$ra[1] / $$rb[1], " times\n";
print STDERR $$ra[1] *10000 / ( $lines ), " sec. for 10000 addresses\n";
print STDERR $$rb[1] *10000 / ( $lines ), " sec. for 10000 addresses\n";

exit 0;
