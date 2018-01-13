#! perl
use strict;
use warnings;

use Test::More;
use B qw(svref_2object);
use Unicode::Japanese qw(unijp);

Unicode::Japanese->new(''); # load xs code.
if( $Unicode::Japanese::xs_loaderror )
{
  plan skip_all => 'xs not loaded';
}

{
  package MY::TieObject;
  sub TIESCALAR
  {
    my $pkg = shift;
    my $ref = shift;
    bless $ref, $pkg;
  }
  sub FETCH
  {
    my $this = shift;
    $$this;
  }
}

plan tests => 3 + 4;

pretest();
test();

sub pretest
{
  my $val = undef;
  tie my $obj, 'MY::TieObject', \$val;

  is(SvOK($obj), undef, "[pre] first: undef, SvOK:false");

  $val = "test";
  is(SvOK($obj), undef, "[pre] set, but get magic not handled, SvOK:false");

  my $var1 = defined($obj);
  is(SvOK($obj), 1, "[pre] get magic handled");
}

sub test
{
  my $uj = Unicode::Japanese->new();
  is($Unicode::Japanese::xs_loaderror, '', "[test] xs enabled");

  local($^W) = 1;
  local($SIG{__DIE__}) = 'DEFAULT';

  is($uj->_u2s(undef), undef, "[test] undef");

  do{
    # fixed in v087.
    my $val = undef;
    tie my $obj, 'MY::TieObject', \$val;
    $val = "test";
    is($uj->_u2s($obj), "test", "[test] set2");
  };

  do{
    my $val = undef;
    tie my $obj, 'MY::TieObject', \$val;
    $val = "test";
    my $var = defined($obj);
    is($uj->_u2s($obj), "test", "[test] set2");
  };
}


sub SvOK
{
  Unicode::Japanese::__SvOK($_[0]) ? 1 : undef;
}
