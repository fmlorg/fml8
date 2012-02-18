#!/usr/bin/perl -I. -w

# find out why it died if not running under make

$debug = 0; 

$Time::ParseDate::debug = $debug;

BEGIN {
	$okat = 12;
	$ENV{'LANG'} = 'C';
	$ENV{'TZ'} = 'PST8PDT'; 

	%k = (
		'%' =>	'%',
		'a' =>	'Sat',
		'A' =>	'Saturday',
		'b' =>	'Nov',
		'h' =>	'Nov',
		'B' =>	'November',
		'c' =>	"Sat Nov 19 21:05:57 1994",
		'd' =>	'19',
		'D' =>	'11/19/94',
		'e' =>	'19',
		'f' =>	'.500',
		'F' =>	'.500000',
		'H' =>	'21',
		'I' =>	'09',
		'j' =>	'323',
		'k' =>	'21',
		'l' =>	' 9',
		'm' =>	'11',
		'M' =>	'05',
		'n' =>	"\n",
		'o' =>	'19th',
		'p' =>	"PM",
		'r' =>	"09:05:57 PM",
		'R' =>	"21:05",
		'S' =>	"57",
		't' =>	"\t",
		'T' =>	"21:05:57",
		'U' =>	"46",
		'v' =>	"19-Nov-1994",
		'w' =>	"6",
		'W' =>	"46",
		'x' =>	"11/19/94",
		'y' =>  "94",
		'Y' =>  "1994",
		'X' =>	"21:05:57",
		'Z' =>	"PST"
		);

	$sdt_start_line = __LINE__+2;
	@sdt = (
		796969332, ['950404 00:22:12 "EDT'],
		796969332, ['950404 00:22:12.500 "EDT'],
		796969332.5, ['950404 00:22:12.500 "EDT', SUBSECOND => 1],
		786437763, ['Fri Dec  2 22:56:03 1994', NOW => 785300000],
		786408963, ['Fri Dec  2 22:56:03 GMT+0 1994', NOW => 785300000],
		786408963, ['Fri Dec  2 22:56:03.500 GMT+0 1994', NOW => 785300000],
		786408963.5, ['Fri Dec  2 22:56:03.500 GMT+0 1994', SUBSECOND => 1, NOW => 785300000],
		786437763, ['Fri Dec  2 22:56:03 GMT-8 1994', NOW => 785300000],
		786437760, ['94/12/02.22:56', NOW => 785300000],
		786437760, ['1994/12/02 10:56Pm', NOW => 785300000],
		786437760, ['1994/12/2 10:56 PM', NOW => 785300000],
		786437760, ['12/02/94 22:56', NOW => 785300000],
		786437760, ['12/2/94 10:56Pm', NOW => 785300000],
		786437760, ['94/12/2 10:56 pm', NOW => 785300000],
		786437763, ['94/12/02 22:56:03', NOW => 785300000],   
		786437763, ['94/12/02 22:56:03.500', NOW => 785300000],   
		786437763.5, ['94/12/02 22:56:03.500', SUBSECOND => 1, NOW => 785300000],   
		786437763, ['94/12/02 10:56:03:500PM', NOW => 785300000],   
		786437763.5, ['94/12/02 10:56:03:500PM', SUBSECOND => 1, NOW => 785300000],   
		786437760, ['10:56Pm 94/12/02', NOW => 785300000],
		786437763, ['22:56:03 1994/12/02', NOW => 785300000],
		786437763, ['22:56:03.5 1994/12/02', NOW => 785300000],
		786437763.5, ['22:56:03.5 1994/12/02', SUBSECOND => 1,  NOW => 785300000],
		786437760, ['22:56 1994/12/2', NOW => 785300000],
		786437760, ['10:56PM 12/02/94', NOW => 785300000],
		786437760, ['10:56 pm 12/2/94', NOW => 785300000],
		786437760, ['22:56 94/12/2', NOW => 785300000],
		786437760, ['10:56Pm 94/12/02', NOW => 785300000],
		796980132, ['Tue Apr 4 00:22:12 PDT 1995'],
		796980132, ['April 4th 1995 12:22:12AM', ZONE => PDT],
		827878812, ['Tue Mar 26 14:20:12 1996'],		
		827878812, ['Tue Mar 26 14:20:12 1996', SUBSECOND => 1],
		827878812, ['Tue Mar 26 14:20:12.5 1996'],
		827878812.5, ['Tue Mar 26 14:20:12.5 1996', SUBSECOND => 1],
		827878812, ['Tue Mar 26 14:20:12 GMT-0800 1996'],
		827878812, ['Tue Mar 26 17:20:12 EST 1996'],
		827878812, ['Tue Mar 26 17:20:12 GMT-0500 1996'],
		827878812, ['Tue Mar 26 22:20:12 GMT 1996'],
		827878812, ['Tue Mar 26 22:20:12 +0000 (GMT) 1996'],
		827878812, ['Tue, 26 Mar 22:20:12 +0000 (GMT) 1996'],
		784394917, ['Wed, 9 Nov 1994 7:28:37'],
		784887518, ['Tue, 15 Nov 1994 0:18:38'], 
		788058300, ['21 dec 17:05', NOW => 785300000],
		802940400, ['06/12/1995'],
		802940400, ['12/06/1995', UK => 1],
		802940400, ['12/06/95', UK => 1],
		802940400, ['06.12.1995'],
		803026800, ['13/06/1995'],
		803026800, ['13/06/95'],
		784394917, ['Wed, 9 Nov 1994 15:28:37 +0000 (GMT)'],
		827878812, ['Tue Mar 26 23:20:12 GMT+0100 1996'],
		827878812, ['Wed Mar 27 05:20:12 GMT+0700 1996'],
		827878812, ['Wed Mar 27 05:20:12 +0700 1996'],
		827878812, ['Wed Mar 27 05:20:12 +07:00 1996'],
		827878812, ['Wed Mar 27 05:20:12 +0700 (EST) 1996'],
		796980132, ['1995/04/04 00:22:12 PDT'],
		796720932, ['1995/04 00:22:12 PDT'],
		796980132, ['1995/04/04 00:22:12 PDT'],
		796980132, ['Tue, 4 Apr 95 00:22:12 PDT'],
		796980132, ['Tue 4 Apr 1995 00:22:12 PDT'],
		796980132, ['04 Apr 1995 00:22:12 PDT'],
		796980132, ['4 Apr 1995 00:22:12 PDT'],
		796980132, ['Tue, 04 Apr 00:22:12 PDT', NOW => 796980132],
		796980132, ['Tue 04 Apr 00:22:12 PDT', NOW => 796980132],
		796980132, ['04 Apr 00:22:12 PDT', NOW => 796980132],
		796980132, ['Apr 04 00:22:12 PDT', NOW => 796980132],
		796980132, ['Apr 4 00:22:12 PDT', NOW => 796980132],
		796980132, ['Tue, Apr 4 00:22:12 PDT', NOW => 796980132],
		796980132, ['Apr 4 1995 00:22:12 PDT'],
		796980132, ['April 4th 1995 00:22:12 PDT'],
		796980132, ["April 4th, '95 00:22:12 PDT"],
		796980132, ["April 4th 00:22:12 PDT", NOW => 796980132],
		796980132, ['95/04/04 00:22:12 PDT'],
		796980132, ['04/04/95 00:22:12 PDT'],
		796720932, ['95/04 00:22:12 PDT'],
		796720932, ['04/95 00:22:12 PDT'],
		796980132, ['04/04 00:22:12 PDT', NOW => 796980132],
		796980132, ['040495 00:22:12 PDT'],
		796980132, ['950404 00:22:12 PDT'],
		796969332, ['950404 00:22:12 EDT'],
		796980132, ['04.04.95 00:22:12', ZONE => PDT],
		796980120, ['04.04.95 00:22', ZONE => PDT],
		796978800, ['04.04.95 12AM', ZONE => PDT],
		796978800, ['04.04.95 12am', ZONE => PDT],
		796980120, ['04.04.95 0022', ZONE => PDT],
		796980132, ['04.04.95 12:22:12am', ZONE => PDT],
		797023332, ['950404 122212', ZONE => PDT],
		797023332, ['122212 950404', ZONE => PDT, TIMEFIRST => 1],
		796980120, ['04.04.95 12:22AM', ZONE => PDT],
		796978800, ['95/04/04 midnight', ZONE => PDT],
		796978800, ['95/04/04 Midnight', ZONE => PDT],
		797022000, ['95/04/04 Noon', ZONE => PDT],
		797022000, ['95/04/04 noon', ZONE => PDT],
		797022000, ['95/04/04 12Pm', ZONE => PDT],
		796978803, ['+3 secs', NOW => 796978800],
		796979600, ['+0800 seconds', NOW => 796978800],
		796986000, ['+2 hour', NOW => 796978800],
		796979400, ['+10min', NOW => 796978800],
		796979400, ['+10 minutes', NOW => 796978800],
		797011203, ['95/04/04 +3 secs', ZONE => EDT, NOW => 796935600],
		797062935, ['4 day +3 secs', ZONE => PDT, NOW => 796720932],
		797062935, ['now + 4 days +3 secs', ZONE => PDT, NOW => 796720932],
		797062935, ['now +4 days +3 secs', ZONE => PDT, NOW => 796720932],
		796720932, ['now', ZONE => PDT, NOW => 796720932],
		796720936, ['now +4 secs', ZONE => PDT, NOW => 796720932],
		796735332, ['now +4 hours', ZONE => PDT, NOW => 796720932],
		797062935, ['+4 days +3 secs', ZONE => PDT, NOW => 796720932],
		797062935, ['+ 4 days +3 secs', ZONE => PDT, NOW => 796720932],
		797062929, ['4 day -3 secs', ZONE => PDT, NOW => 796720932],
		796375329, ['-4 day -3 secs', ZONE => PDT, NOW => 796720932],
		796375329, ['now - 4 days -3 secs', ZONE => PDT, NOW => 796720932],
		796375329, ['now -4 days -3 secs', ZONE => PDT, NOW => 796720932],
		796720928, ['now -4 secs', ZONE => PDT, NOW => 796720932],
		796706532, ['now -4 hours', ZONE => PDT, NOW => 796720932],
		796375329, ['-4 days -3 secs', ZONE => PDT, NOW => 796720932],
		796375329, ['- 4 days -3 secs', ZONE => PDT, NOW => 796720932],
		797322132, ['1 week', NOW => 796720932],
		801987732, ['2 month', NOW => 796720932],
		804579732, ['3 months', NOW => 796720932],
		859879332, ['2 years', NOW => 796720932],
		797671332, ['Wed after next', NOW => 796980132],
		797498532, ['next monday', NOW => 796980132],
		797584932, ['next tuesday', NOW => 796980132],
		797066532, ['next wEd', NOW => 796980132],
		796378932, ['last tuesday', NOW => 796980132],
		796465332, ['last wednesday', NOW => 796980132],
		796893732, ['last monday', NOW => 796980132],
		797036400, ['today at 4pm', NOW => 796980132],
		797080932, ['tomorrow +4hours', NOW => 796980132],
		796950000, ['yesterday at 4pm', NOW => 796980132],
		796378932, ['last week', NOW => 796980132],
		794305332, ['last month', NOW => 796980132],
		765444132, ['last year', NOW => 796980132],
		797584932, ['next week', NOW => 796980132],
		799572132, ['next month', NOW => 796980132],
		828606132, ['next year', NOW => 796980132],
		836391600, ['July 3rd, 4:00AM 1996 ', DATE_REQUIRED =>1, TIME_REQUIRED=>1, NO_RELATIVE=>1, NOW=>796980132],
		783718105, ['Tue, 01 Nov 1994 11:28:25 -0800'],
		202779300, ['5:35 pm june 4th CST 1976'],
		236898000, ['5pm EDT 4th july 1977'],
		236898000, ['5pm EDT 4 july 1977'],
		819594300, ['21-dec 17:05', NOW => 796980132],
		788058300, ['21-dec 17:05', NOW => 796980132, PREFER_PAST => 1],
		819594300, ['21-dec 17:05', NOW => 796980132, PREFER_FUTURE => 1],
		793415100, ['21-feb 17:05', NOW => 796980132, PREFER_PAST => 1],
		824951100, ['21-feb 17:05', NOW => 796980132, PREFER_FUTURE => 1],
		819594300, ['21/dec 17:05', NOW => 796980132],
		756522300, ['21/dec/93 17:05'],
		788058300, ['dec 21 1994 17:05'],
		788058300, ['dec 21 94 17:05'],
		788058300, ['dec 21 94 17:05'],
		796465332, ['Wednesday', NOW => 796980132, PREFER_PAST => 1],
		796378932, ['Tuesday', NOW => 796980132, PREFER_PAST => 1],
		796893732, ['Monday', NOW => 796980132, PREFER_PAST => 1],
		797066532, ['Wednesday', NOW => 796980132, PREFER_FUTURE => 1],
		797584932, ['Tuesday', NOW => 796980132, PREFER_FUTURE => 1],
		797498532, ['Monday', NOW => 796980132, PREFER_FUTURE => 1],
		802915200, ['06/12/1995', ZONE => GMT],
		828860438, ['06/Apr/1996:23:00:38 -0800'],
		828860438, ['06/Apr/1996:23:00:38'],
		828943238, ['07/Apr/1996:23:00:38 -0700'],
		828878618, ['07/Apr/1996:12:03:38', ZONE => GMT],
		828856838, ['06/Apr/1996:23:00:38 -0700'],
		828946838, ['07/Apr/1996:23:00:38 -0800'],
		895474800, ['5/18/1998'],
		796980132, ['04/Apr/1995:00:22:12', ZONE => PDT], 
		796983732, ['04/Apr/1995:00:22:12 -0800'], 
		796983732, ['04/Apr/1995:00:22:12', ZONE => PST], 
		202772100, ['5:35 pm june 4th 1976 EDT'],
		796892400, ['04/03', NOW => 796980132, PREFER_PAST => 1],
		765702000, ['04/07', NOW => 796980132, PREFER_PAST => 1],
		883641600, ['1/1/1998', VALIDATE => 1],
		852105600, ['1/1/1997'],
		852105600, ['last year', NOW => 883641600],
		820483200, ['-2 years', NOW => 883641600],
		832402800, ['-2 years', NOW => 895474800],
		891864000, ['+3 days', NOW => 891608400],
		891777600, ['+2 days', NOW => 891608400],
		902938515, ['1998-08-12 12:15:15', ZONE => 'EDT'],
		946684800, ['2000-01-01 00:00:00', ZONE => GMT],
		1262304000, ['2010-01-01 00:00:00', ZONE => GMT],
		757065600, ['12/28/93', NOW => 1262304000],
		1924675200, ['12/28/30', NOW => 1262304000],
		946751430, ['Jan  1 2000 10:30:30AM'],
		946722083, ['Sat Jan  1 02:21:23 2000'],
		946774740, ['Jan 1 2000 4:59PM', WHOLE => 1],
		946774740, ['Jan  1 2000  4:59PM', WHOLE => 1],
		0, ['1970/01/01 00:00:00', ZONE => GMT],
		796980132, ['Tue 4 Apr 1995 00:22:12 PDT 8', WHOLE => 0],
		789008700, ['dec 32 94 17:05'],
		796983072, ['1995/04/04 00:71:12 PDT'],
		undef, ['1995/04/04 00:71:12 PDT', VALIDATE => 1],
		undef, ['38/38/21', VALIDATE => 1],
		undef, ['dec 32 94 17:05', VALIDATE => 1],
		undef, ['Tue 4 Apr 1995 00:22:12 PDT 8', WHOLE => 1],
		undef, ['Tue 4 Apr 199 00:22:12 PDT'],
		1924675200, ['12/28/30', NOW => 1262304000, PREFUR_FUTURE => 1],
		1924675200, ['28/12/30', NOW => 1262304000, PREFUR_FUTURE => 1, UK => 1],
		-1578240000, ['12/28/19', NOW => 902938515, PREFER_PAST => 1],
		-347155200, ['1959-01-01 00:00:00', ZONE => GMT],
		-158083200, ['12/28/64', NOW => 902938515],
		-1231084800, ['12/28/30', NOW => 1262304000, PREFER_PAST => 1],
		-345600, ['1969-12-28 00:00:00', ZONE => GMT],
		-1231084800, ['28/12/30', NOW => 1262304000, PREFER_PAST => 1, UK => 1],
		1577520000, ['12/28/19', NOW => 902938515, PREFER_FUTURE => 1],
		1766908800, ['12/28/25', NOW => 902938515],
		958521600, ['17 May 2000 00:00:00 GMT'],
		979718400, ['1/17/01', NOW => 993067736],
		995353200, ['7/17/01', NOW => 993067736],
		995353200, ['7/17/01', NOW => 993067736, PREFER_FUTURE => 1],
		995366188, ['17/07/2001 18:36:28 +0800', WHOLE => 1],
		995366188, ['17/07/2001 18:36:28+0800', WHOLE => 1],
		995330188, ['17/07/2001 0:36:28+0000', WHOLE => 1],
		995416588, ['17/07/2001 24:36:28+0000', WHOLE => 1],
		undef, ['17/07/2001 24:36:28+0000', WHOLE => 1, VALIDATE => 1],
		995330188, ['17/07/2001 0:36:28+0000', WHOLE => 1, VALIDATE => 1],
		796375332, ['4 days ago', WHOLE =>1, ZONE => PDT, NOW => 796720932],
		796720931, ['1 second ago', WHOLE =>1, ZONE => PDT, NOW => 796720932],
		796375331, ['4 days 1 second ago', WHOLE =>1, ZONE => PDT, NOW => 796720932],
		796375331, ['1 second 4 days ago', WHOLE =>1, ZONE => PDT, NOW => 796720932],
		953467299, ['Sun Mar 19 17:31:39 IST 2000'],
		784111777, ['Sunday, 06-Nov-94 08:49:37 GMT' ],
		954933672, ['Wed Apr  5 13:21:12 MET DST 2000' ],
		729724230, ['1993-02-14T13:10:30', NOW => 796980132],
#ISO8601		729724230, ['19930214T131030', NOW => 796980132],
		14400, ['+4 hours', NOW => 0],
		345600, ['+4 days', NOW => 0],
		957744000, ['Sunday before last', NOW => 958521600],
		957139200, ['Sunday before last', NOW => 958348800],
		796720930.5, ['1.5 second ago', WHOLE =>1.5, ZONE => PDT, NOW => 796720932],
		796720930.5, ['1 1/2 second ago', WHOLE =>1.5, ZONE => PDT, NOW => 796720932],
		5, ['5 seconds', UK => 1, NOW => 0],
		6, ['5 seconds', UK => 1, NOW => 1],
		1078876800, ['2004-03-10 00:00:00 GMT'],
		1081551599, ['-1 second +1 month', NOW => 1078876800, ZONE => 'PDT'],
		1081526399, ['-1 second +1 month', NOW => 1078876800, ZONE => 'GMT'],
		1304661600, ['11pm', NOW => 1304611460],
		1304636400, ['11pm', NOW => 1304611460, GMT => 1],
		1304557200, ['1am', NOW => 1304611460, GMT => 1],
		1246950000, ['2009/7/7'],
		-1636819200, ['1918/2/18'],
		1246950000, ['2009/7/7'],
		1256435700, ['2009-10-25 02:55:00', ZONE => 'MET'],
		1256439300, ['+ 1 hour', NOW => 1256435700, ZONE => 'MET'],
		1256464500, ['2009-10-25 02:55:00', ZONE => 'PDT'],
		1256468100, ['+ 1 hour', NOW => 1256464500, ZONE => 'PDT'],
		1256468100, ['2009-10-25 02:55:00', ZONE => 'PST'],
		1256471700, ['+ 1 hour', NOW => 1256468100, ZONE => 'PST'],
		[1304622000, 'Foo'], ['12pm Foo', NOW => 1304611460, WHOLE => 0],
		undef, ['Foo 12pm', NOW => 1304611460, WHOLE => 0],
		undef, ['Foo noon', NOW => 1304611460, WHOLE => 0],
		undef, ['Foo midnight', NOW => 1304611460, WHOLE => 0],
		1011252345, ['Wed Jan 16 23:25:45 2002'],
		1012550400, ['Feb 1', NOW => 1011252345],
		1012550400, ['Feb 1', NOW => 1011252345, FUZZY => 1, PREFER_FUTURE => 1],
		1012550400, ['2/1/02', NOW => 1011252345, FUZZY => 1, PREFER_FUTURE => 1],
		1011247200, ['6am', GMT => 1, NOW => 1011252345],
		1256435700, ['2009-10-25 02:55:00', ZONE => 'MEZ'],
		);

	%tztests = (
		"YDT"  =>   -8*3600,         # Yukon Daylight
		"HDT"  =>   -9*3600,         # Hawaii Daylight
		"BST"  =>   +1*3600,         # British Summer   
		"MEST" =>   +2*3600         # Middle European Summer  
	);

}

use Time::CTime;
use Time::JulianDay;
use Time::ParseDate;
use Time::Local;
use Time::Timezone;
use POSIX qw(tzset);

tzset;

my @x = localtime(785307957);
my @y = gmtime(785307957);
my $hd = $y[2] - $x[2];
$hd += 24 if $hd < 0;
$hd %= 24;
if ($hd != 8) {
	print "1..0 # Skipped: It seems localtime() does not honor \$ENV{TZ} when set in the test script.  Please set the TZ environment variable to PST8PDT and rerun.";
	print "hd = $hd, x = @x, y = @y\n" if $debug || -t STDOUT;
	exit 0;
}

my $before_big = $okat-1+scalar(keys %k)+scalar(keys %tztests);

printf "1..%d\n", $before_big + scalar(grep(ref($_), @sdt));

print "ok 1\n";

$epoch = ($Time::JulianDay::jd_epoch - 2440588) * 86400
	+ $Time::JulianDay::jd_epoch_remainder;
print STDERR "\nEpoch = $epoch\n" if $epoch;

$etime = 785307957.5 - $epoch;


eval " 1/0; ";  # tests a bug in ctime!
$x = ctime($etime);
print $x eq "Sat Nov 19 21:05:57 PST 1994\n" ? "ok 2\n" : "not ok 2\n";

print julian_day(1994,11,19) == 2449676 ? "ok 3\n" : "not ok 3\n";

@x = inverse_julian_day(2449676);

print (($x[0] == 1994 and $x[1] == 11 and $x[2] == 19) ? "ok 4\n" : "not ok 4\n");

print "ok 5\n";

print day_of_week(2449676) == 6 ? "ok 6\n" : "not ok 6\n";

$bs = 786439995 - $epoch;

use vars qw($isdst $wday $yday);
($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime($bs);

$jdtgm = jd_timegm($sec,$min,$hour,$mday,$mon,$year);
$jdtl = jd_timelocal($sec,$min,$hour,$mday,$mon,$year);
$tltl = timelocal($sec,$min,$hour,$mday,$mon,$year);

$year += 100 if $year < 70;
$jd = julian_day($year+1900, $mon+1, $mday);
$s = jd_secondsgm($jd, $hour, $min, $sec);
$lo = tz_local_offset($bs);

print <<"" if $debug;
	s = $s
	bs = $bs
	jdtgm = $jdtgm
	jdtl = $jdtl
	tltl = $tltl
	lo = $lo

print $s == $bs ? "ok 7\n" : "not ok 7\n";

print $jdtgm == $bs ? "ok 8\n" : "not ok 8\n";

print $jdtl == $bs+8*3600 ? "ok 9\n" : "not ok 9\n";

print $tltl == $bs+8*3600 ? "ok 10\n" : "not ok 10\n";

print $lo == - 28800 ? "ok 11\n" : "no ok 11\n";

################### make these last...
$c = $okat;

@lt = localtime($etime);
$lt[0] += ($etime - int($etime));
foreach $i (sort keys %k) {
	$x = strftime("-%$i-", @lt);
	print $x eq "-$k{$i}-" ? "ok $c # $i - $k{$i}\n" : "not ok $c # $i - $k{$i}: $x\n";
	if ($debug && $x ne "-$k{$i}-") {
		print "strftime(\"-%$i-\") = $x.\n\tshould be: $k{$i}.\n";
		exit(0);
	}
	$c++;
}

foreach $i (keys %tztests) {
	$tzo = tz_offset($i,799572132);
	print $tzo eq $tztests{$i} ? "ok $c\n" : "not ok $c\n";
	if (($debug || -t STDOUT) && $tzo ne $tztests{$i}) {
		print "tz_offset($i) = $tzo != $tztests{$i}\n";
		exit(0);
	}
	$c++;
}


while (@sdt) {
	$es = shift(@sdt);
	my $eremaining;
	if (ref($es)) {
		$eremaining = $es->[1];
		$es = $es->[0];
	}
	$es -= $epoch if defined($es);
	$ar = shift(@sdt);
	$toparse = shift(@$ar);
	%opts = @$ar;
	if (defined $opts{NOW}) {
		$opts{NOW} -= $epoch;
	}
	$opts{WHOLE} = 1 unless defined $opts{WHOLE};
	my $remaining;
	if (defined $eremaining) {
		($s, $remaining) = parsedate($toparse, %opts);
	} else {
		$s = parsedate($toparse, %opts);
	}
	if (! defined($es) && ! defined($s)) {
		print "ok $c # $toparse\n";
	} elsif (defined($es) && defined($s) && $es == $s) {
		print "ok $c # $toparse\n";
	} else {
		print "not ok $c # $toparse\n";
		if (-t STDOUT || $debug) {
			if (defined($es)) {
				print strftime("Expected($es):    %c %Z\n", localtime($es));
			} else {
				print "Expected undef\n";
			}

			print strftime("\tGot($s): %c %Z", localtime($s));
			print strftime(" (%m/%d %I:%M %p GMT)\n", gmtime($s));
			print "\tInput: $toparse\n";
			for my $zk (keys %opts) {
				my $zv = $opts{$zk};
				if ($zk eq 'NOW') {
					print strftime("\t\tNOW => %c %Z\n", localtime($zv));
				} else {
					print "\t\t$zk => $zv\n";
				}
			}
			if (-t STDOUT) {
				print "The parse...\n";
				$Time::ParseDate::debug = 1;
				&parsedate($toparse, %opts);
				printf "Test that failed was on line %d\n",	
					$c-$before_big+$sdt_start_line-1;
				exit(0);
			}
		}
	}
	if (defined($eremaining)) {
		$c++;
		if ($remaining eq $eremaining) {
			print "ok $c # remaining = '$eremaining'\n";
		} else {
			print "not ok $c # remaining = '$eremaining'\n";
			if (-t STDOUT || $debug) {
				print "# got '$remaining' instead\n";
			}
		}
	}
	$c++;
}
