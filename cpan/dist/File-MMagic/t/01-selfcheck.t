# perl-test
# $Id: 01-selfcheck.t 192 2006-01-04 07:57:15Z knok $

use strict;
use Test;

BEGIN { plan tests => 1 };

use File::MMagic;

my $magic = File::MMagic->new();
my $ret = $magic->checktype_filename('t/01-selfcheck.t');
ok($ret eq 'text/plain');
