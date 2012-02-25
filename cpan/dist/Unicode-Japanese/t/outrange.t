
use Test;

use Unicode::Japanese;

BEGIN { plan tests => 6 }

## check from utf8 convert
## U+2665 BLACK HEART SUIT (in Miscellaneous Symbols) into some charsets.

my $string;

# sjis
$string = new Unicode::Japanese "\xe2\x99\xa5";
ok($string->sjis, "&#9829;", "U+2665 (9829) => sjis");

# euc
$string = new Unicode::Japanese "\xe2\x99\xa5";
ok($string->euc, "&#9829;", "U+2665 (9829) => eucjp");

# jis(iso-2022-jp)
$string = new Unicode::Japanese "\xe2\x99\xa5";
ok($string->jis, "&#9829;", "U+2665 (9829) => jis");

# imode
$string = new Unicode::Japanese "\xe2\x99\xa5";
ok($string->sjis_imode, "?", "U+2665 (9829) => imode");

# dot-i
$string = new Unicode::Japanese "\xe2\x99\xa5";
ok($string->sjis_doti, "?", "U+2665 (9829) => doti");

# j-sky
$string = new Unicode::Japanese "\xe2\x99\xa5";
ok($string->sjis_jsky, "?", "U+2665 (9829) => jsky");


