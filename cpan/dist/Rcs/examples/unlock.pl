#!/usr/local/bin/perl -w
#------------------------------------------
# Unlock RCS file
#------------------------------------------
use strict;
use Rcs;

Rcs->bindir('/usr/bin');
Rcs->quiet(0);
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");
my $revision = shift || $obj->head;
die "Revision $revision does not exist\n"
    unless grep /^$revision$/, $obj->revisions;

$obj->rcs("-u${revision}");

