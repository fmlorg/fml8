
use Test;

use Unicode::Japanese;

BEGIN { plan tests => 7 }

## check from utf8 convert

my $string;

# sjis
$string = new Unicode::Japanese "\xe6\x84\x9b";
ok($string->sjis, "\x88\xa4");

# euc
$string = new Unicode::Japanese "\xe6\x84\x9b";
ok($string->euc, "\xb0\xa6");

# jis(iso-2022-jp)
$string = new Unicode::Japanese "\xe6\x84\x9b";
ok($string->jis, "\x1b\x24\x42\x30\x26\x1b\x28\x42");

# imode
$string = new Unicode::Japanese "\xf3\xbf\xa2\xa8";
ok($string->sjis_imode, "\xf8\xa8");

# dot-i
$string = new Unicode::Japanese "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e";
ok($string->sjis_doti, "\xf0\x48\xf3\x8e");

# j-sky
$string = new Unicode::Japanese "\xf3\xbf\xb0\xb2";
ok($string->sjis_jsky, "\e\$F2\x0f");

# j-sky(packed)
$string = new Unicode::Japanese "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84";
ok($string->sjis_jsky, "\e\$F2D\x0f");


