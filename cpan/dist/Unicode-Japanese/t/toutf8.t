
use Test;
use strict;
use Unicode::Japanese;
#print STDERR $Unicode::Japanese::PurePerl?"PurePerl mode\n":"XS mode\n";

BEGIN { plan tests => 9 }

## check to utf8 convert

$]>=5.008 and eval 'use bytes', $@ && die $@;

my $string;
use lib 't';
require 'esc.pl';

# sjis
$string = new Unicode::Japanese "\x88\xa4", 'sjis';
ok($string->utf8(), "\xe6\x84\x9b");

# euc
$string = new Unicode::Japanese "\xb0\xa6", 'euc';
ok($string->utf8(), "\xe6\x84\x9b");

# jis(iso-2022-jp)
$string = new Unicode::Japanese "\x1b\x24\x42\x30\x26\x1b\x28\x42", 'jis';
ok($string->utf8(), "\xe6\x84\x9b");

# imode
$string = new Unicode::Japanese "\xf8\xa8", 'sjis-imode';
ok($string->utf8(), "\xf3\xbf\xa2\xa8", 'sjis-imode');

# dot-i
$string = new Unicode::Japanese "\xf0\x48\xf3\x8e", 'sjis-doti';
ok($string->utf8(), "\xf3\xbf\x81\x88\xf3\xbf\x8e\x8e");

# j-sky  (4632 ==> 0ffc32)
$string = new Unicode::Japanese::PurePerl "\e\$F2\x0f", 'sjis-jsky';
ok(escfull($string->utf8()), escfull("\xf3\xbf\xb0\xb2"));
$string = new Unicode::Japanese "\e\$F2\x0f", 'sjis-jsky';
ok(escfull($string->utf8()), escfull("\xf3\xbf\xb0\xb2"));

# j-sky(packed) (4632 4644 ==> 0ffc32 0ffc44)
$string = new Unicode::Japanese::PurePerl "\e\$F2D\x0f", 'sjis-jsky';
ok($string->utf8(), "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84");
$string = new Unicode::Japanese "\e\$F2D\x0f", 'sjis-jsky';
ok($string->utf8(), "\xf3\xbf\xb0\xb2\xf3\xbf\xb1\x84");

