#!/usr/bin/perl -w

use strict;
use diagnostics;
$| = 1; # autoflush
use vars qw(@ARGV $ARGV);
use Jcode;

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

my %code2str = 
    (
     'euc' =>  $euc,
     'jis' =>  $jis,
     'sjis' => $sjis,
     'ucs2' => $ucs2,
     'utf8' => $utf8,
     );

# by Value

for my $icode (keys %code2str){
    my $ok;
    my $j = Jcode->new($code2str{$icode}, $icode);
    for my $ocode (keys %code2str){
	if ($j->$ocode() eq $code2str{$ocode}){
	    $ok = "ok";
	}else{
	    $ok = "not ok";
	}
	profile(sprintf("ASCII|X201|X208: %4s -> %4s %s %d\n", 
			$icode, $ocode, $ok, ++$n ));

    }
}

# x212

# x212

$file = "t/x0212.euc";
open F, $file or die "$file:$!";
read F, $euc, -s $file;
#profile(sprintf("prep:  euc ok %d\n", ++$n));
$jis  = Jcode::euc_jis($euc);

%code2str = 
    (
     'euc' =>  $euc,
     'jis' =>  $jis,
     );

# by Value

for my $icode (keys %code2str){
    my $ok;
    my $j = Jcode->new($code2str{$icode}, $icode);
    for my $ocode (keys %code2str){
	if ($j->$ocode() eq $code2str{$ocode}){
	    $ok = "ok";
	}else{
	    $ok = "not ok";
	}
	profile(sprintf("X212: %4s -> %4s %s %d\n", 
			$icode, $ocode, $ok, ++$n ));

    }
}

print 1, "..", $NTESTS, "\n";
for my $TEST (@TESTS){
    print $TEST; 
}









