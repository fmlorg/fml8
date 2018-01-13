# perl-test
# $Id$

use strict;
use Test;

BEGIN { plan tests => 1 };

use File::MMagic;

my $ans = "text/plain";
my $magic = File::MMagic->new();
my $ret = $magic->checktype_contents('text conthook');
ok($ret eq $ans);
