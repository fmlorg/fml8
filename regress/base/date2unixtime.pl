#!/usr/bin/env perl
#
# $FML$
#

use FML::Date;

require 'ctime.pl';

my $t    = time;
my $date = ctime( $t );

chop $date;

my $tx =  FML::Date::date_to_unixtime( $date ), "\t";

print "* date -> unixtime: $t => $date => $tx\n";

if ($t == $tx) {
   print "ok\n";
}
else {
   print "fail\n";
}

exit 0;
