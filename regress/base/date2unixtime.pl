#!/usr/bin/env perl
#
# $FML: date2unixtime.pl,v 1.2 2001/11/18 02:22:10 fukachan Exp $
#

use strict;
use Mail::Message::Date;

my $debug = defined $ENV{'debug'} ? 1 : 0;

require 'ctime.pl';

my $t    = time;
my $date = ctime( $t );

chop $date;

my $tx = Mail::Message::Date::date_to_unixtime( $date );

print "* date -> unixtime: $t => $date => $tx\n" if $debug;

if ($t == $tx) {
   print "ok\n";
}
else {
   print "fail\n";
}

exit 0;
