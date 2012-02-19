#!/usr/bin/perl

use strict;
use Jcode;
use Test;
BEGIN { plan tests => 50 }

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
my $double = $code2str{utf8} x 2;
for my $icode (@code2str){
    for my $ocode (@code2str){
	my $j = 
	    jcode($code2str{$icode},$icode)->append($code2str{$ocode},$ocode);
	myok($j->utf8, $double,"jcode(\$str,$icode)->append(\$str,$ocode)");
	$j =  jcode($code2str{$icode}, $icode);
	$j .= $code2str{$ocode};
	myok($j->utf8, $double,"jcode(\$str,$icode) .= \$str");
    }
}

__END__
