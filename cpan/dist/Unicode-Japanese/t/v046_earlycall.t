## ----------------------------------------------------------------------------
# t/v046_earlycall.t
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
use Test::More;
use Unicode::Japanese;

plan tests => 3;

is($Unicode::Japanese::xs_loaderror, undef, "xsubs is not loaded yet");
eval{ Unicode::Japanese->getcode(""); };
my $err = $@;
is($err, '', "getcode success");
is($Unicode::Japanese::xs_loaderror, '', "xsubs is loaded successfully");
