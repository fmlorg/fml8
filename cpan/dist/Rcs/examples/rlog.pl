#!/usr/local/bin/perl -w
#------------------------------------------
# Use rlog utility.
#------------------------------------------
use strict;
use Rcs;

my $obj = Rcs->new;

# call quiet and bindir as objest methods
$obj->quiet(1);
$obj->bindir('/usr/bin');

print "Quiet mode set\n" if Rcs->quiet;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

print $obj->rlog;
