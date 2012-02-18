#!/usr/bin/perl -I. -w

use strict;
use warnings;
use Test::More; 
use Time::ParseDate;
use Time::CTime;
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
	import Test::More skip_all => "It seems localtime() does not honor \$ENV{TZ} when set in the test script.";
	exit 0;
}
import Test::More qw(no_plan);

$ENV{'TZ'} = 'MET'; 
tzset;

@x = localtime(785307957);
@y = gmtime(785307957);
$hd = $y[2] - $x[2];
$hd += 24 if $hd < 0;
$hd %= 24;
if ($hd != 23) {
	print "1..0 # Skipped: It seems localtime() does not honor \$ENV{TZ} when set in the test script.\n";
	exit 0;
}

$finished = 0;

$ENV{TZ} = 'MET';
tzset;

my $t0 = parsedate("2009-10-25 02:55:00");
my $t1 = parsedate("+ 1 hour", NOW => scalar(parsedate("2009-10-25 02:55:00")));
my $lt1 = scalar(localtime($t1));

is($t0, 1256435700, "testing TZ=MET seconds");
is($t1, 1256439300, "testing TZ=MET seconds +1 h");
is($lt1, "Sun Oct 25 03:55:00 2009", "testing TZ=MET +1 h localtime");

$ENV{TZ} = "PST8PDT";
tzset;

my $p0 = parsedate("2009-11-01 01:55:00");
my $p1 = parsedate("+ 1 hour", NOW => scalar(parsedate("2009-11-01 01:55:00")));
my $lp0 = scalar(localtime($p0));
my $lp1 = scalar(localtime($p1));
my $lpz0 = strftime("%R %Z",localtime($p0));
my $lpz1 = strftime("%R %Z",localtime($p1));

is($p0, 1257065700, "testing PST8PDT");
is($lp0, "Sun Nov  1 01:55:00 2009", "testing PST8PDT localtime");
is($p1, 1257069300, "testing PST8PDT");
is($lp1, "Sun Nov  1 01:55:00 2009", "testing PST8PDT localtime");
is($lpz0, "01:55 PDT", "zone 0");
is($lpz1, "01:55 PST", "zone 1");

$finished = 1;

