#!/usr/bin/perl
#

use strict;
use Jcode;
BEGIN {
    if ($] < 5.008001){
        print "1..0 # Skip: Perl 5.8.1 or later required\n";
        exit 0;
    }
    require Test::More;
    Test::More->import(tests => 5);
}

use Data::Dumper;

my $unistr = "\x{262f}"; # YIN YANG
my $j = jcode($unistr);

is($j->euc, '?', "FALLBACK: default");
is($j->fallback(Jcode::FB_PERLQQ)->euc,   '\x{262f}', "FALLBACK: perlqq");
is($j->fallback(Jcode::FB_XMLCREF)->euc,  '&#x262f;', "FALLBACK: xmlcref");
is($j->fallback(Jcode::FB_HTMLCREF)->euc, '&#9775;',  "FALLBACK: htmlcref");

$j = jcode("\x{5C0F}\x{98FC}\x{5F3E}");
is($j->MIME_Header, "=?UTF-8?B?5bCP6aO85by+?=", '$j->MIME_Header');
__END__

