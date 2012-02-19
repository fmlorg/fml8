#!/usr/local/bin/perl

use strict;
use Benchmark;
use blib;

$| = 1;

my %code2str;

my @enc = qw/euc sjis jis utf8/;
for my $enc (@enc){
    my $file = "t/table.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str{$enc}, -s $file;
    close F;
}

use Jcode;
use Unicode::Japanese;
my $tests;

for my $f (@enc){
    for my $t (@enc){
	$f eq $t and next;
	$tests->{"$f->$t"} = 
	    sub {
		no strict 'refs';
		Jcode->new($code2str{$f}, $f)->$t eq $code2str{$t}
			or die;
	    };
    }
}

timethese(0,
	  $tests);
__END__
my %tests;
for my $mod (qw/Jcode Unicode::Japanese/){
    eval qq{ require $mod };
    $@ and next;
    "$mod loaded.";
    no strict 'refs';
    $tests{$mod} = sub {
	
    }
}
