
use Test;

use Unicode::Japanese qw(PurePerl);

BEGIN { plan tests => 15 }

## getcode method

sub test
{
  my $src = shift;
  my $icode = shift;
  my $code = Unicode::Japanese->new->getcode($src);
  ok($code, $icode, 'src:'.unpack('H*',$src));
}

my $code;

$code = Unicode::Japanese->new->getcode("\x00\x00\xfe\xff");
ok($code, 'utf32');

$code = Unicode::Japanese->new->getcode("\xff\xfe\x00\x00");
ok($code, 'utf32');

$code = Unicode::Japanese->new->getcode("\xfe\xff");
ok($code, 'utf16');

$code = Unicode::Japanese->new->getcode("\xff\xfe");
ok($code, 'utf16');

$code = Unicode::Japanese->new->getcode("\x00\x00\x61\x1b");
ok($code, 'utf32-be');

$code = Unicode::Japanese->new->getcode("\x1b\x61\x00\x00");
ok($code, 'utf32-le');

$code = Unicode::Japanese->new->getcode("love");
ok($code, 'ascii');

$code = Unicode::Japanese->new->getcode("\x1b\x24\x42\x30\x26\x1b\x28\x42");
ok($code, 'jis');

$code = Unicode::Japanese->new->getcode("\e\$EE\x0f");
ok($code, 'sjis-jsky');

$code = Unicode::Japanese->new->getcode("\xb0\xa6");
ok($code, 'euc');

$code = Unicode::Japanese->new->getcode("\x88\xa4");
ok($code, 'sjis');

test("\x88\xa4\xf8\xdf", 'sjis-imode');

$code = Unicode::Japanese->new->getcode("\x88\xa4\xf1\xb5");
ok($code, 'sjis-doti');

$code = Unicode::Japanese->new->getcode("\xe6\x84\x9b");
ok($code, 'utf8');

$code = Unicode::Japanese->new->getcode("\xcd\x10\x89\x01");
ok($code, 'unknown');


