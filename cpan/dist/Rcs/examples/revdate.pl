#!/usr/local/bin/perl -w
#------------------------------------------
# Get revision date
#------------------------------------------
use strict;
use Rcs;

Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");
my $revision = shift || $obj->head;
die "Revision $revision does not exist\n"
    unless grep /^$revision$/, $obj->revisions;

# scalar mode
my $date_num = $obj->revdate($revision);
print "Revision : Date number = $revision : $date_num\n";

my $date_str = localtime($date_num);
print "Revision : Date string = $revision : $date_str\n";

# list mode
my @list_date = $obj->revdate($revision);
print "Revision : Date array = $revision : @list_date\n";

