## ----------------------------------------------------------------------------
# t/v045_imodexs.t
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
use Test::More;
use Unicode::Japanese;

# xs is loaded in first invocation of `new'.
my $xs = Unicode::Japanese->new();

# to avoid used-only-once warning, read twice.
my $err = ($Unicode::Japanese::xs_loaderror,$Unicode::Japanese::xs_loaderror)[0];
if( $err =~ /Can't locate loadable object/ )
{
  plan skip_all => 'no xs module';
}

plan tests => 1;

# imode, EXT-1.
$xs->set("\xf9\xb1", 'sjis-imode1');
my $u8 = $xs->utf8;
is(unpack("H*", $u8), unpack("H*", "?"), "imode-ext1 with imode1 will be '?'");

