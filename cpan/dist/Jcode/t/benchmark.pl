#!/usr/local/bin/perl

use Benchmark;

my $count = $ARGV[0] || 16;

open F, "t/table.euc" or die "$!";
while(<F>){
    push @src, $_;
}

for $ocode (qw/euc jis sjis/){
    print "euc -> $ocode\n";
    timethese($count, {
	"Jcode.pm (OOP)  " => \&Jcode_oop,
	"Jcode.pm (Trad.)" => \&Jcode_trad,
	"jcode.pl        " => \&jcode_test,
    }
	      );
}

sub jcode_test{
    require "jcode.pl";
    for (@src){
      &jcode::convert(\$_, $ocode, 'euc');
    }
}

sub Jcode_trad{
    use Jcode;
    for (@src){
	&Jcode::convert(\$_, $ocode, 'euc');
    }
}

sub Jcode_oop{
    use Jcode;
    no strict "refs";
    my $j = new Jcode;
    for (@src){
	$j->set(\$_, 'euc')->$ocode();
    }
}

