#!/usr/local/bin/perl -w
#------------------------------------------
# Check-out source file.
#------------------------------------------
use strict;
use Rcs;

Rcs->bindir('/usr/bin');
Rcs->quiet(0);  # turn off quiet mode
my $obj = Rcs->new;

print "Quiet mode set\n" if Rcs->quiet;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");
my $revision = shift || $obj->head;
die "Revision $revision does not exist\n"
    unless grep /^$revision$/, $obj->revisions;

$obj->co("-l${revision}");
