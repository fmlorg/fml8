
use Test;

use Unicode::Japanese;

BEGIN { plan tests => 6 }

## convert an illustrated letter between different types

my $string;

# dot-i/j-sky to imode
$string = new Unicode::Japanese "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e";
ok($string->sjis_imode, "\xf9\x8e\x82\xd2");

$string = new Unicode::Japanese "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84";
ok($string->sjis_imode, "\xf9\x82\xf9\x8f");


# imode/j-sky to dot-i
$string = new Unicode::Japanese "\xf3\xbf\xa2\xa8";
ok($string->sjis_doti, "\xf0\x76");

$string = new Unicode::Japanese "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84";
ok($string->sjis_doti, "\xf4\xa8\xf0\x49");

# imode/dot-i to j-sky
$string = new Unicode::Japanese "\xf3\xbf\xa2\xa8";
ok($string->sjis_jsky, "\x1b\x24\x46\x60\x0f");

# U+? U+000ff38e
$string = new Unicode::Japanese "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e";
ok($string->sjis_jsky, "\x1b\x24\x46\x43\x0f\x82\xd2");


