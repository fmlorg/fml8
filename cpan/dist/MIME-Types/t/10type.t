#!/usr/bin/perl -w
#
# Test reporting warnings, errors and family.
#

use Test;
use strict;

use lib qw(. t);

BEGIN {plan tests => 25}

use MIME::Type;

my $a = MIME::Type->new(type => 'x-appl/x-zip', extensions => [ 'zip', 'zp' ]);
ok($a);
ok($a->type eq 'x-appl/x-zip');
ok($a->simplified eq 'appl/zip');
ok($a->simplified('text/plain') eq 'text/plain');
ok(MIME::Type->simplified('x-xyz/abc') eq 'xyz/abc');
ok($a->mainType eq 'appl');
ok($a->subType eq 'zip');
ok(!$a->isRegistered);

my @ext = $a->extensions;
ok(@ext==2);
ok($ext[0] eq 'zip');
ok($ext[1] eq 'zp');
ok($a->encoding eq 'base64');
ok($a->isBinary);
ok(not $a->isAscii);

my $b = MIME::Type->new(type => 'TEXT/PLAIN', encoding => '8bit');
ok($b);
ok($b->type eq 'TEXT/PLAIN');
ok($b->simplified eq 'text/plain');
ok($b->mainType eq 'text');
ok($b->subType eq 'plain');
@ext = $b->extensions;
ok(@ext==0);
ok($b->encoding eq '8bit');
ok(not $b->isBinary);
ok($b->isAscii);
ok($b->isRegistered);

my $c = MIME::Type->new(type => 'applications/x-zip');
ok(!$c->isRegistered);
