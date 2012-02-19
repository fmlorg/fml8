#!/usr/local/bin/perl
use strict;
use lib 't';
use Benchmark qw/:all/;

my $count = $ARGV[0] || -1;

open F, "t/table.euc" or die "$!";
our @src; 
our $ocode;
while(<F>){
    push @src, $_;
}


our %jcode2encode = (
		     jis => '7bit-jis',
		     euc => 'euc-jp',
		     sjis => 'shiftjis',
		    );

for (qw/euc jis sjis ucs2 utf8/){
    $ocode = $_;
    print "euc -> $ocode\n";
    my $res = timethese($count, 
		     {
		      "Encode.pm"        => \&Encode_test,
		      "Jcode.pm (OOP)"   => \&Jcode_oop,
		      "Jcode.pm (Trad.)" => \&Jcode_trad,
		      /^u/ ? () : ("jcode.pl"         => \&jcode_test),
		     }
		    );
    cmpthese($res);
}
sub Encode_test{
    use Encode qw/from_to/;
    for (@src){
	my $tmp = $_;
	from_to($tmp, 'euc-jp', $jcode2encode{$ocode} || $ocode);
    }
}
sub jcode_test{
    require "jcode.pl";
    for (@src){
	my $tmp = $_;
	&jcode::convert(\$tmp, $ocode, 'euc');
    }
}

sub Jcode_trad{
    use Jcode;
    for (@src){
	my $tmp = $_;
	&Jcode::convert(\$tmp, $ocode, 'euc');
    }
}

sub Jcode_oop{
    use Jcode;
    no strict "refs";
    my $j = new Jcode;
    for (@src){
	my $tmp = $_;
	$j->set(\$tmp, 'euc')->$ocode();
    }
}

