#!/usr/bin/perl -I. -w

use strict;
use warnings;
use Test::More;
use Time::ParseDate;
use POSIX qw(tzset);

my $finished;
END { ok($finished, 'finished') if defined $finished }

$ENV{'LANG'} = 'C';
$ENV{'TZ'} = 'PST8PDT'; 
tzset;

my @x = localtime(785307957);
my @y = gmtime(785307957);
my $hd = $y[2] - $x[2];
$hd += 24 if $hd < 0;
$hd %= 24;
if ($hd != 8) {
	import Test::More skip_all => "It seems localtime() does not honor \$ENV{TZ} when set in the test script.  Please set the TZ environment variable to PST8PDT and rerun.";
	exit 0;
}
import Test::More qw(no_plan);

$finished = 0;

is(parsedate('1918/2/18'), -1636819200, "year 1918");
is(parsedate('2009/7/7'), 1246950000, "year 2009");

$finished = 1;

