#!/usr/bin/perl -w

use strict;
use diagnostics;
$| = 1; # autoflush
use vars qw(@ARGV $ARGV);
use Jcode;

$Jcode::DEBUG ||= $ARGV[0] ? $ARGV[0] : 0;

my ($NTESTS, @TESTS) ;

sub profile {
    no strict 'vars';
    my $profile = shift;
    print $profile if $ARGV[0];
    $profile =~ m/(not ok|ok) (\d+)$/o;
    $profile = "$1 $2\n";
    $NTESTS = $2;
    push @TESTS, $profile;
}


my $n = 0;

my $file = "t/table.euc";
open F, $file or die "$file:$!";
my $euc;
read F, $euc, -s $file;
profile(sprintf("prep:  euc ok %d\n", ++$n));

my $jis  = Jcode::euc_jis($euc);
profile(sprintf("prep:  jis ok %d\n", ++$n)) unless $jis eq $euc;

my $sjis = Jcode::euc_sjis($euc);
profile(sprintf("prep: sjis ok %d\n", ++$n)) unless $sjis eq $euc;

Jcode::load_module("Jcode::Unicode");

my $ucs2 = Jcode::euc_ucs2($euc);
profile(sprintf("prep: ucs2 ok %d\n", ++$n)) unless $ucs2 eq $euc;

my $utf8 = Jcode::euc_utf8($euc);
profile(sprintf("prep: utf8 ok %d\n", ++$n)) unless $utf8 eq $euc;

profile(sprintf("getcode:  euc ok %d\n", ++$n)) 
    unless Jcode::getcode($euc) ne 'euc';
profile(sprintf("getcode:  jis ok %d\n", ++$n))
    unless Jcode::getcode($jis) ne 'jis';
profile(sprintf("getcode: sjis ok %d\n", ++$n)) 
    unless Jcode::getcode($sjis) ne 'sjis';
profile(sprintf("getcode: ucs2 ok %d\n", ++$n))
    unless Jcode::getcode($ucs2) ne 'ucs2';
profile(sprintf("getcode: utf8 ok %d\n", ++$n))
    unless Jcode::getcode($utf8) ne 'utf8';

print 1, "..", $NTESTS, "\n";
for my $TEST (@TESTS){
    print $TEST; 
}









