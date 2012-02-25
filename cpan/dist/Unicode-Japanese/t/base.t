## ----------------------------------------------------------------------------
# t/base.t
# -----------------------------------------------------------------------------
# $Id: base.t 4499 2002-10-31 07:48:02Z hio $
# -----------------------------------------------------------------------------

use strict;
use Test;
BEGIN { plan tests => 8 }

# -----------------------------------------------------------------------------
# load module

require Unicode::Japanese;
ok(1);

import Unicode::Japanese;
ok(1);

# -----------------------------------------------------------------------------
# check new and set/get

my $string;

$string = new Unicode::Japanese;
ok($string);

$string = new Unicode::Japanese 'abcde';
ok($string->get, 'abcde');

$string = new Unicode::Japanese;
$string->set('abcde');
ok($string->get, 'abcde');

# -----------------------------------------------------------------------------
# check new and set/get *PurePerl*

$string = new Unicode::Japanese::PurePerl;
ok($string);

$string = new Unicode::Japanese::PurePerl 'abcde';
ok($string->get, 'abcde');

$string = new Unicode::Japanese::PurePerl;
$string->set('abcde');
ok($string->get, 'abcde');

