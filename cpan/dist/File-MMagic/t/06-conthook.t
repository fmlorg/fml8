# perl-test
# $Id$

use strict;
use Test;

BEGIN { plan tests => 1 };

use File::MMagic;

my $ans = "text/plain; conthook";
my $magic = File::MMagic->new();
$magic->addContainerHook($ans, sub {
	my $self = shift;
	my $data = shift;
	return "text/plain; conthook" if $data =~ /conthook/;
	return ""; });
my $ret = $magic->checktype_container('text conthook');
ok($ret eq $ans);
