#!/usr/bin/perl -w

use strict;
use Jcode;
use Test;
BEGIN { plan tests => 4 }

my $seq = 0;
sub myok{ # overloads Test::ok;
    my ($a, $b, $comment) = @_;
    print "not " if $a ne $b;
    ++$seq;
    print "ok $seq # $comment\n";
}

my $file;

my $hankaku; $file = "t/hankaku.euc"; open F, $file or die "$file:$!";
read F, $hankaku, -s $file;

my $zenkaku; $file = "t/zenkaku.euc"; open F, $file or die "$file:$!";
read F, $zenkaku, -s $file;

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
	myok($out, $code2str{$ocode}, 
	     "H2Z: $icode -> $ocode");
    }
}
__END__




