# perl-test
# $Id: 01-selfcheck.t,v 1.2 2003/11/21 02:25:52 knok Exp $

use strict;
use Test;

BEGIN { plan tests => 1 };

use File::MMagic;

my $magic = File::MMagic->new();
my $ret = $magic->checktype_filename('t/01-selfcheck.t');
ok($ret eq 'text/plain');
