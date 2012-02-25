
use Test;

use Unicode::Japanese;

BEGIN { plan tests => 4 }

## Util method

my $string;

# strlen (KATAKANA-AIU)
$string = new Unicode::Japanese "\xe3\x82\xa2\xe3\x82\xa4\xe3\x82\xa6";
ok($string->strlen, 6);

# strcut (KATAKANA-AIU)
$string = new Unicode::Japanese "\xe3\x82\xa2\xe3\x82\xa4\xe3\x82\xa6";
ok($string->strcut(5)->[0], "\xe3\x82\xa2\xe3\x82\xa4");

# join_csv
$string = new Unicode::Japanese;
$string->join_csv([1, 2, 'abc', '"123"']);
ok($string->get, '1,2,abc,"""123"""' . "\n");

# split_csv
$string = new Unicode::Japanese '1,2,abc,"""123"""';
ok($string->split_csv->[3], '"123"');


