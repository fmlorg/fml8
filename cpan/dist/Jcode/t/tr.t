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

my $hiragana; $file = "t/hiragana.euc"; open F, $file or die "$file:$!";
read F, $hiragana, -s $file;
profile(sprintf("prep:  hiragana ok %d\n", ++$n));

my $katakana; $file = "t/zenkaku.euc"; open F, $file or die "$file:$!";
read F, $katakana, -s $file;
profile(sprintf("prep:  katakana ok %d\n", ++$n));

my $stripped; $file = "t/stripped.euc"; open F, $file or die "$file:$!";
read F, $stripped, -s $file;
profile(sprintf("prep:  stripped ok %d\n", ++$n));

#print jcode($katakana)->tr('A-Za-z¥¡-¥óŽ§-ŽÝ','a-zA-Z¤¡-¤óŽ§-ŽÝ');
#__END__

my %code2str = 
    (
     'A-Za-z¥¡-¥óŽ§-ŽÝ' =>  $katakana,
     'a-zA-Z¤¡-¤óŽ§-ŽÝ' =>  $hiragana,
     );

# by Value

for my $icode (keys %code2str){
    for my $ocode (keys %code2str){
	my $ok;
	my $str = $code2str{$icode};
	my $out = jcode(\$str)->tr($icode, $ocode)->euc;
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

# test tr($s,'','d');

my $ok = (jcode($hiragana)->tr('¤¡-¤ó','','d')->euc eq $stripped) ?
"ok" : "not ok";

profile(sprintf("H2Z: %s -> %s %s %d\n", 
		'¤¡-¤ó', "\'\' \'d\'", $ok, ++$n ));

print 1, "..", $NTESTS, "\n";
for my $TEST (@TESTS){
    print $TEST; 
}





