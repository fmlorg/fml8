#!/usr/local/bin/perl -w
#------------------------------------------
# Check-in source file.
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

# archive file exists
if (! -e $obj->rcsdir . '/' . $obj->arcfile) {
    print "Initial Check-in\n";
    $obj->ci("-u");
}

# create archive file
else {
    print "Check-in\n";
    $obj->ci("-l");
}
