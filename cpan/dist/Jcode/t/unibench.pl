#!/usr/local/bin/perl

use ExtUtils::testlib;
use Benchmark;
use strict;
use lib qw(.);

$| = 1;

require Jcode;
$Jcode::DEBUG = 1;
$Jcode::NOXS = $ARGV[0];
print "done.\n";
my $file = "t/table.euc";
open F, $file or die "$file:$!";
my $euc;
read F, $euc, -s $file;

my $ucs2 = Jcode->new($euc)->ucs2;
my $utf8 = Jcode->new($euc)->utf8;

my $count = $ARGV[1] || 16;

timethese($count, {
    "utf8->ucs2" =>  \&utf8_ucs2,
    "ucs2->utf8" =>  \&ucs2_utf8,
    "ucs2->euc" =>   \&ucs2_euc,
    "ucs2->utf8" =>  \&ucs2_utf8,
});

sub utf8_ucs2{
    &Jcode::utf8_ucs2($utf8);
}

sub ucs2_utf8{
    &Jcode::ucs2_utf8($ucs2);
}

sub euc_ucs2{
    &Jcode::euc_ucs2($ucs2);
}

sub ucs2_euc{
    &Jcode::ucs2_euc($ucs2);
}

