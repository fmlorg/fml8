#!/usr/local/bin/perl -w
#------------------------------------------
# Add users to access list.
#------------------------------------------
use strict;
use Rcs;

Rcs->bindir('/usr/bin');
Rcs->quiet(0);
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

my @users = qw(beavis butthead);
$obj->rcs("-a@users");

my $filename = $obj->file;
my @access_list = $obj->access;
print "Users @access_list are on the access list of $filename\n";
