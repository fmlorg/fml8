#!/usr/bin/env perl
#
# $FML: date2unixtime.pl,v 1.1 2001/07/08 14:02:02 fukachan Exp $
#

use Mail::Message::Date;

require 'ctime.pl';

my $t    = time;
my $date = ctime( $t );

chop $date;

my $tx = Mail::Message::Date::date_to_unixtime( $date ), "\t";

print "* date -> unixtime: $t => $date => $tx\n";

if ($t == $tx) {
   print "ok\n";
}
else {
   print "fail\n";
}

exit 0;
