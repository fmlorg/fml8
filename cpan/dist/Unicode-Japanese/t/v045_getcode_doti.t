## ----------------------------------------------------------------------------
# t/v045_getcode.t
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
use Test::More;
use Unicode::Japanese;

# xs is loaded in first invocation of `new'.
my $xs = Unicode::Japanese->new();
my $pp = Unicode::Japanese::PurePerl->new();

# to avoid used-only-once warning, read twice.
my $err = ($Unicode::Japanese::xs_loaderror,$Unicode::Japanese::xs_loaderror)[0];
if( $err =~ /Can't locate loadable object/ )
{
  plan skip_all => 'no xs module';
}

plan tests => 2;


# f340 is available on both au and doti.
# But f040 is available on only doti.
my $str = "\xf3\x40\xf0\x40";
is($xs->getcode($str), "sjis-doti", "xs");
is($pp->getcode($str), "sjis-doti", "pp");
