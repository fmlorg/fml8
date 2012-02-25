# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

END {print "not ok 1\n" unless $loaded;}
use HTML::CalendarMonthSimple;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# test instantiation of a new calendar object
my $cal = new HTML::CalendarMonthSimple();
if ($cal) { print "ok 2\n"; } else { die "not ok 2\n"; }

