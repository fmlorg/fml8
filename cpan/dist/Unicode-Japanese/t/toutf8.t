
use Test;

use Unicode::Japanese;

BEGIN { plan tests => 7 }

## check to utf8 convert

my $string;

# sjis
$string = new Unicode::Japanese "\x88\xa4", 'sjis';
ok($string->get, "\xe6\x84\x9b");

# euc
$string = new Unicode::Japanese "\xb0\xa6", 'euc';
ok($string->get, "\xe6\x84\x9b");

# jis(iso-2022-jp)
$string = new Unicode::Japanese "\x1b\x24\x42\x30\x26\x1b\x28\x42", 'jis';
ok($string->get, "\xe6\x84\x9b");

# imode
$string = new Unicode::Japanese "\xf8\xa8", 'sjis-imode';
ok($string->get, "\xf3\xbf\xa2\xa8");

# dot-i
$string = new Unicode::Japanese "\xf0\x48\xf3\x8e", 'sjis-doti';
ok($string->get, "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e");

# j-sky
$string = new Unicode::Japanese "\e\$F2\x0f", 'sjis-jsky';
ok($string->get, "\xf3\xbf\xb0\xb2");

# j-sky(packed)
$string = new Unicode::Japanese "\e\$F2D\x0f", 'sjis-jsky';
ok($string->get, "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84");

