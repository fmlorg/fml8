#!/usr/bin/env perl
#
# $FML: date2unixtime.pl,v 1.3 2002/04/18 14:18:07 fukachan Exp $
#

use strict;
use Mail::Message::Date;

my $debug = defined $ENV{'debug'} ? 1 : 0;

require 'ctime.pl';

my $t    = time;
my $date = ctime( $t );

chop $date;

my $tx = Mail::Message::Date::date_to_unixtime( $date );

print STDERR "Mail::Message::Date ";
print STDERR "(date -> unixtime): $t => $date => $tx\n" if $debug;

if ($t == $tx) {
   print STDERR "ok\n";
}
else {
   print STDERR "fail\n";
}

exit 0;
