#!/usr/local/bin/perl -w
#------------------------------------------
# Access dates hash
#------------------------------------------
use strict;
use Rcs;

#Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

# sort by date
my %dates_hash = $obj->dates;
my $revision;
my %dates;
foreach $revision (keys %dates_hash) {
    my $date = $dates_hash{$revision};
    $dates{$date}{$revision} = 1;
}

my $date;
foreach $date (reverse sort keys %dates) {
    foreach $revision (keys %{ $dates{$date} }) {
        my $date_str = localtime($date);
        print "Revision : Date = $revision : $date_str\n";
    }
}

# scalar mode returns most recent date
print "\n";
my $most_recent = localtime($obj->dates);
print "Most recent revision date = $most_recent\n";
