#!/usr/bin/env perl
#
# Test reporting warnings, errors and family.
#

use strict;
use warnings;

use Test::More tests => 25;
use lib qw(lib t);

use MIME::Type;

my $a = MIME::Type->new(type => 'x-appl/x-zip', extensions => [ 'zip', 'zp' ]);
ok(defined $a);

is($a->type, 'x-appl/x-zip');
is($a->simplified, 'appl/zip');
is($a->simplified('text/plain'), 'text/plain');
is(MIME::Type->simplified('x-xyz/abc'), 'xyz/abc');
is($a->mainType, 'appl');
is($a->subType, 'zip');
ok(!$a->isRegistered);

my @ext = $a->extensions;
cmp_ok(scalar @ext, '==', 2);
is($ext[0], 'zip');
is($ext[1], 'zp');
is($a->encoding, 'base64');
ok($a->isBinary);
ok(not $a->isAscii);

my $b = MIME::Type->new(type => 'TEXT/PLAIN', encoding => '8bit');
ok(defined $b);
is($b->type, 'TEXT/PLAIN');
is($b->simplified, 'text/plain');
is($b->mainType, 'text');
is($b->subType, 'plain');
@ext = $b->extensions;
cmp_ok(scalar @ext, '==', 0);
is($b->encoding, '8bit');
ok(not $b->isBinary);
ok($b->isAscii);
ok($b->isRegistered);

my $c = MIME::Type->new(type => 'applications/x-zip');
ok(!$c->isRegistered);
