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
my $file;

my $hankaku; $file = "t/hankaku.euc"; open F, $file or die "$file:$!";
read F, $hankaku, -s $file;
profile(sprintf("prep:  hankaku ok %d\n", ++$n));

my $zenkaku; $file = "t/zenkaku.euc"; open F, $file or die "$file:$!";
read F, $zenkaku, -s $file;
profile(sprintf("prep:  zenkaku ok %d\n", ++$n));

my %code2str = 
    (
     'h2z' =>  $zenkaku,
     'z2h' =>  $hankaku,
     );

# by Value

for my $icode (keys %code2str){
    for my $ocode (keys %code2str){
	my $ok;
	my $str = $code2str{$icode};
	my $out = jcode(\$str)->$ocode()->euc;
	if ($out eq $code2str{$ocode}){
	    $ok = "ok";
	}else{
	    $ok = "not ok";
	    print $out;
	}
	profile(sprintf("H2Z: %s -> %s %s %d\n", 
			$icode, $ocode, $ok, ++$n ));
    }
}

print 1, "..", $NTESTS, "\n";
for my $TEST (@TESTS){
    print $TEST; 
}





