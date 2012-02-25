
use strict;
#use warnings;

use Test::More tests => 14;

# -----------------------------------------------------------------------------
# load module
#
use Unicode::Japanese;

sub xs { _conv('Unicode::Japanese', @_); }
sub pp { _conv('Unicode::Japanese::PurePerl', @_); }
sub _conv
{
  my $pkg   = shift;
  my $str   = shift;
  my $icode = shift or die "no icode";
  my $out = $pkg->new($str, $icode)->utf8;
  esc($out);
}
sub esc
{
  my $out = shift;
  $out =~ s/\\/\\\\/g;
  $out =~ s/\e/\\e/g;
  $out =~ s/\$/\\\$/g;
  $out =~ s/([^ -~])/"\\x".unpack("H*",$1)/ge;
  $out;
}

# -----------------------------------------------------------------------------
# run tests.
#
&test;

sub test
{
	foreach my $icode (
		'sjis-jsky',
		'sjis-jsky1',
		'sjis-jsky2',
		'jis-jsky',
		'jis-jsky1',
		'jis-jsky2',
	)
	{
		is(xs("\e\$G\x21", $icode), esc("\xf3\xbf\xb4\xa1"), "(xs) $icode"),
		is(pp("\e\$G\x21", $icode), esc("\xf3\xbf\xb4\xa1"), "(pp) $icode"),
	}
	
	my $xs = Unicode::Japanese->new();
	my $pp = Unicode::Japanese::PurePerl->new();
	is($xs->getcode("\e\$G\x21"), "sjis-jsky", "(xs) getcode");
	is($pp->getcode("\e\$G\x21"), "sjis-jsky", "(pp) getcode");
}

