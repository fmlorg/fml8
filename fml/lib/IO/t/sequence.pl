#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: lock.pl,v 1.1 2004/04/10 07:40:02 fukachan Exp $
#

use strict;
use Carp;

my $debug = 0;
my $i     = 0;
my $file  = "/tmp/io.adapter.$$";
my $map   = "file:$file";
my %log   = ();
my %pid   = ();
my $fail  = 0;
my $reason = '';

### MAIN ###
print "${file}->sequence_increment() ... ";

use IO::Adapter;

for my $i (0 .. 5) {
    my $obj = new IO::Adapter $map;
    my $id  = $obj->sequence_increment();

    unless ($id == ($i + 1)) {
	$reason .= "wrong sequence returned";
	$reason .= "\t\n";
	$fail++;
    }

    if ($obj->error()) {
	$reason .= $obj->error();
	$reason .= "\t\n";
	$fail++;
    }
}

show_result();


#
# 2. replace
#
$fail   = 0;
$reason = '';

print "${file}->seqeunce_replace()   ... ";
my $obj = new IO::Adapter $map;
$obj->sequence_replace(10);
if ($obj->error()) {
    $reason .= $obj->error();
    $reason .= "\t\n";
    $fail++;
}

show_result();

exit 0;


sub show_result
{
    print $fail ? "fail\n" : "ok\n";
    if ($fail) {
	print "\t", $reason, "\n";
    }

    if ($debug) {
	my $obj = new IO::Adapter $map;
	$obj->open();
	print "debug = ", $obj->getline(), "\n";
    }
}
