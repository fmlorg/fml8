#!/usr/local/bin/perl -w
#------------------------------------------
# Test daterev method
#------------------------------------------
use strict;
use Time::Local;
use lib '.';
use Rcs;

Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

my @date_array = @ARGV;
my($year, $mon, $mday, $hour, $min, $sec) = @date_array;
$mon--;        # convert to 0-11 range
my $target_time = timegm($sec, $min, $hour, $mday, $mon, $year);

print "Called as 6 argument method\n";
# scalar mode
my $revision = $obj->daterev(@date_array);
my $date_str = gmtime($obj->revdate($revision));
print "Date : Revision = $date_str : $revision\n\n";


# list mode
print "List mode\n";
my @revisions = $obj->daterev(@date_array);
foreach (@revisions) {
    $date_str = gmtime($obj->revdate($_));
    print "Date : Revision = $date_str : $_\n";
}


print "\n\n\n";
print "Called as 1 argument method\n";
print "Time number is $target_time\n";
$revision = $obj->daterev($target_time);
$date_str = gmtime($obj->revdate($revision));
print "Date : Revision = $date_str : $revision\n\n";


# list mode
print "List mode\n";
@revisions = $obj->daterev($target_time);
foreach (@revisions) {
    $date_str = gmtime($obj->revdate($_));
    print "Date : Revision = $date_str : $_\n";
}

