#!/usr/bin/env perl
#
# $FML: journaledfile.pl,v 1.3 2002/04/18 14:18:07 fukachan Exp $
#

use strict;
use lib qw(../../fml/lib);
use Tie::JournaledFile;

$| = 1;
print "Tie::JournaledFile ";

my $debug = defined $ENV{'debug'} ? 1 : 0;
my %db   = ();
my $file = '/tmp/fml5/cache.txt';
my $buf  = '';
my $key  = "rudo$$";
chop($buf = `date`);

tie %db, 'Tie::JournaledFile', { file => $file };
$db{ $key } = $buf;
untie %db;

print "   ", `ls -l $file` if $debug;

tie %db, 'Tie::JournaledFile', { file => $file };

print "verify written string ... " if $debug;
if ($db{ $key } eq $buf) {
    print "ok\n";
} 
else {
    print "fail\n";
    print "   >", $db{ $key }, "<\n";
    print "   >", $buf, "<\n";
}

exit 0;
