# perl-test
# $Id: 02-extmagic.t 192 2006-01-04 07:57:15Z knok $

use strict;
use Test;

BEGIN { plan tests => 1 };

use File::MMagic;

my $magic = File::MMagic->new();
$magic->addMagicEntry("0\tstring\t#\\ perl-test\tapplication/x-perl-test");
my $ret = $magic->checktype_filename('t/02-extmagic.t');
ok($ret eq 'application/x-perl-test');
