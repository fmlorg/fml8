#!/usr/local/bin/perl -w
#------------------------------------------
# Parse RCS archive file.
#------------------------------------------
use strict;
use Rcs;

Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

my $head_rev = $obj->head;
my $locker = $obj->lock;
my $author = $obj->author;
my @access = $obj->access;
my @revisions = $obj->revisions;

my $filename = $obj->file;

if ($locker) {
    print "Head revision $head_rev is locked by $locker\n";
}
else {
    print "Head revision $head_rev is unlocked\n";
}

if (@access) {
    print "\nThe following users are on the access list of file $filename\n";
    map { print "User: $_\n"} @access;
}

print "\nList of all revisions of $filename\n";
foreach (@revisions) {
    print "Revision: $_\n";
}
