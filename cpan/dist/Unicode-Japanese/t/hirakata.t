
use Test;

use Unicode::Japanese;

BEGIN { plan tests => 2 }

## convert hiragana <-> katakana

my $string;

# hiragana -> katakana
$string = new Unicode::Japanese "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86";
$string->hira2kata;
ok($string->get, "\xe3\x82\xa2\xe3\x82\xa4\xe3\x82\xa6");

# katakana -> hiragana
$string = new Unicode::Japanese "\xe3\x82\xa2\xe3\x82\xa4\xe3\x82\xa6";
$string->kata2hira;
ok($string->get, "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86");


