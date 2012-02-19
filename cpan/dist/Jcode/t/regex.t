#!/usr/bin/perl
#
# 入口
#
use strict;
use Jcode;
BEGIN {
    if ($] < 5.008001){
        print "1..0 # Skip: Perl 5.8.1 or later required\n";
        exit 0;
    }
    require Test::More;
    Test::More->import(tests => 7);
}


my $str = '漢字、カタカナ、ひらがなの入ったString';
my $re_hira = "([ぁ-ん]+)";
my $j = jcode($str, 'euc');
my ($match) = $j->m($re_hira);
is($match, "ひらがなの", qq(m//));
$j->s("カタカナ","片仮名");
$j->s("ひらがな","平仮名");
is("$j", "漢字、片仮名、平仮名の入ったString", "s///");

local($SIG{__WARN__}) = sub{}; # suppress eval error
my $p = __PACKAGE__;
our ($M_FLAG, $S_FLAG) = (0, 0);

$j->m("/);\$$p\:\:M_FLAG+=1;(/", "");
$j->m("", ");\$$p\:\:M_FLAG+=2;(");
$j->s("//);\$$p\:\:S_FLAG+=1;(s/", "", "");
$j->s("", "/);\$$p\:\:S_FLAG+=2;(/", "");
$j->s("", "", ");\$$p\:\:S_FLAG+=4;(");

is($M_FLAG & 1, 0, "m// pattern escape test");
is($M_FLAG & 2, 0, "m// flag escape test");
is($S_FLAG & 1, 0, "s/// pattern escape test");
is($S_FLAG & 2, 0, "s/// replace escape test");
is($S_FLAG & 4, 0, "s/// flag escape test");

__END__
