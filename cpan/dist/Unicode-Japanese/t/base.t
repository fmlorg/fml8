
use Test;

BEGIN { plan tests => 5 }

require Unicode::Japanese;
ok(1);

import Unicode::Japanese;
ok(1);

## check new and set/get

my $string;

$string = new Unicode::Japanese;
ok($string);

$string = new Unicode::Japanese 'abcde';
ok($string->get, 'abcde');

$string = new Unicode::Japanese;
$string->set('abcde');
ok($string->get, 'abcde');



