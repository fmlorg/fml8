#!/usr/local/bin/perl -w
#------------------------------------------
# rcsclean utility
#------------------------------------------
use strict;
use Rcs;

Rcs->quiet(0);      # turn off quiet mode
Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

print "Quiet mode NOT set\n" unless Rcs->quiet;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

$obj->rcsclean;
