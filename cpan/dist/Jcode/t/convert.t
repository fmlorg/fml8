#!/usr/bin/perl

use strict;
use Jcode;
use Test;
BEGIN { plan tests => 83 }

my $seq = 0;
sub myok{ # overloads Test::ok;
    my ($a, $b, $comment) = @_;
    print "not " if $a ne $b;
    ++$seq;
    print "ok $seq # $comment\n";
}

my %code2str;
for my $enc (qw/euc sjis jis utf8 ucs2/){
    my $file = "t/table.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str{$enc}, -s $file;
    close F;
}
my @code2str = keys %code2str;
check("ascii|x0208");
%code2str = ();
for my $enc (qw/euc jis utf8 ucs2/){
    my $file = "t/x0212.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str{$enc}, -s $file;
    close F;
}
@code2str = keys %code2str;
check("x0212");

sub check{
    my $table = shift;
    for my $icode (@code2str){
	for my $ocode (@code2str){
	    my $str = $code2str{$icode};
	    myok(Jcode::convert($str, $ocode, $icode), $code2str{$ocode},
		 "$table:\$str" . " $icode => $ocode");
	    $str = $code2str{$icode}; # for sure;
	    Jcode::convert(\$str, $ocode, $icode); 
	    myok($str, $code2str{$ocode}, 
		 "$table:\\\$str" . " $icode => $ocode");
	}
    }
}

myok("This is a constant", 
     Jcode::convert("This is a constant", "euc", "sjis"), 
     qq<Jcode::convert("constant" ...)>);
__END__
