#!/usr/bin/env perl
#
# $FML$
#

use strict;
use lib qw(../../fml/lib);
use Tie::JournaledFile;

my %db   = ();
my $file = '/tmp/fml5/cache.txt';
my $buf  = '';
chop($buf = `date`);

tie %db, 'Tie::JournaledFile', { file => $file };
$db{ 'rudo' } = $buf;
untie %db;

print "   ", `ls -l $file`;

tie %db, 'Tie::JournaledFile', { file => $file };

print "verify written string ... ";
if ($db{ 'rudo' } eq $buf) {
    print "ok\n";
} 
else {
    print "fail\n";
    print "   >", $db{'rudo'}, "<\n";
    print "   >", $buf, "<\n";
}

exit 0;
