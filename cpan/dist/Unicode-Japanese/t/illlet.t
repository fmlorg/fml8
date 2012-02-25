
use Test;

use Unicode::Japanese;
use lib 't';
require 'esc.pl';

BEGIN { plan tests => 6 }

## convert an illustrated letter between different types
## (ja:異機種間絵文字変換)

my $string;

# dot-i/j-sky to imode
$string = new Unicode::Japanese "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e";
ok(escfull($string->sjis_imode), escfull("\xf9\x8e\x82\xd2"));

$string = new Unicode::Japanese "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84";
ok(escfull($string->sjis_imode), escfull("\xf9\x82\xf9\x8f"));


# imode/j-sky to dot-i
$string = new Unicode::Japanese "\xf3\xbf\xa2\xa8";
ok(escfull($string->sjis_doti), escfull("\xf0\x76"));

# 0ffc32.0ffc44 (jsky1.4632(NEW).jsky1.4644(枠付き数字９色地]))
# f4a8.f055
$string = new Unicode::Japanese "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84";
ok(escfull($string->sjis_doti), escfull("\xf4\xa8\xf0\x55"));

# imode(0ff8a8) to j-sky
$string = new Unicode::Japanese "\xf3\xbf\xa2\xa8";
ok(escfull($string->sjis_jsky), escfull("\x1b\x24\x46\x60\x0f"));

# U+0FF048 U+0FF38E
$string = new Unicode::Japanese "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e";
ok(escfull($string->sjis_jsky), escfull("\x1b\x24\x46\x43\x0f\x82\xd2"));


