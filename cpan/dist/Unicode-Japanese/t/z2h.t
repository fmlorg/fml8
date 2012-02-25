
use strict;
use Test;
BEGIN { plan tests => 8*2; }

use Unicode::Japanese;
use lib 't';
require 'esc.pl';

#Unicode::Japanese->new();
#$Unicode::Japanese::xs_loaderror and print STDERR "$Unicode::Japanese::xs_loaderror\n";

# -----------------------------------------------------------------------------
# h2z convert
# 

my $string   = Unicode::Japanese->new();
my $ppstring = Unicode::Japanese::PurePerl->new();
my ($set,$expected);

# h2z num
$set = "0129";
$expected = "\xef\xbc\x90\xef\xbc\x91\xef\xbc\x92\xef\xbc\x99";
ok($string->set($set)->h2z()->utf8(),$expected);
ok($ppstring->set($set)->h2z()->utf8(),$expected);

# h2z alpha
$set = "abzABZ";
$expected = "\xef\xbd\x81\xef\xbd\x82\xef\xbd\x9a\xef\xbc\xa1\xef\xbc\xa2\xef\xbc\xba";
ok($string->set($set)->h2z()->utf8(),$expected);
ok($ppstring->set($set)->h2z()->utf8(),$expected);

# h2z symbol
$set = "!#^*(-+~{]>?_";
$expected = "\xef\xbc\x81\xef\xbc\x83\xef\xbc\xbe\xef\xbc\x8a\xef\xbc\x88\xef\xbc\x8d\xef\xbc\x8b\xef\xbd\x9e\xef\xbd\x9b\xef\xbc\xbd\xef\xbc\x9e\xef\xbc\x9f\xef\xbc\xbf";
ok($string->set($set)->h2z()->utf8(),$expected);
ok($ppstring->set($set)->h2z()->utf8(),$expected);

# h2z kana / KUTEN KATA-SMALL-O HIRA-SMALL-O KANA-VU
$set = "\xef\xbd\xa1\xef\xbd\xab\xe3\x81\x89\xef\xbd\xb3\xef\xbe\x9e";
$expected = "\xe3\x80\x82\xe3\x82\xa9\xe3\x81\x89\xe3\x83\xb4";
ok($string->set($set)->h2z()->utf8(),$expected);
ok($ppstring->set($set)->h2z()->utf8(),$expected);

# -----------------------------------------------------------------------------
# z2h convert
# 

# z2h num
$set = "\xef\xbc\x90\xef\xbc\x91\xef\xbc\x92\xef\xbc\x99";
$expected = "0129";
ok($string->set($set)->z2h()->utf8(),$expected);
ok($ppstring->set($set)->z2h()->utf8(),$expected);

# z2h alpha
$set = "\xef\xbd\x81\xef\xbd\x82\xef\xbd\x9a\xef\xbc\xa1\xef\xbc\xa2\xef\xbc\xba";
$expected = "abzABZ";
ok($string->set($set)->z2h()->utf8(),$expected);
ok($ppstring->set($set)->z2h()->utf8(),$expected);

# z2h symbol
$set = "\xef\xbc\x81\xef\xbc\x83\xef\xbc\xbe\xef\xbc\x8a\xef\xbc\x88\xef\xbc\x8d\xef\xbc\x8b\xef\xbd\x9e\xef\xbd\x9b\xef\xbc\xbd\xef\xbc\x9e\xef\xbc\x9f";
$expected = "!#^*(-+~{]>?";
ok($string->set($set)->z2h()->utf8(),$expected);
ok($ppstring->set($set)->z2h()->utf8(),$expected);

# z2h kana, HIRAGANA LETTER SMALL O is kept.
$set = "\xe3\x80\x82\xe3\x82\xa9\xe3\x81\x89\xe3\x83\xb4";
$expected = "\xef\xbd\xa1\xef\xbd\xab\xe3\x81\x89\xef\xbd\xb3\xef\xbe\x9e";
ok($string->set($set)->z2h()->utf8(),$expected);
ok($ppstring->set($set)->z2h()->utf8(),$expected);

