#!/usr/bin/env perl
#
# $FML: journaledfile.pl,v 1.4 2002/05/11 08:34:52 fukachan Exp $
#

use strict;
use lib qw(../../fml/lib);
use Tie::JournaledFile;

$| = 1;

#
# 1. read/write
#
print "Tie::JournaledFile write ... ";

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


#
# 2. keys
#
print "Tie::JournaledFile keys ... ";

my @p = keys %db;
my $count_orig = ` awk '{print $1}' $file | sort | uniq | wc -l `;
my $count = $#p + 1;

if ($count_orig == $count) {
    print "ok\n";
}
else {
    print "fail ($count_orig != $count)\n";
}

exit 0;
