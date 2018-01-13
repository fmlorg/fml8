#!/usr/bin/env perl
#
# Test reporting warnings, errors and family.
#

use strict;
use warnings;

use lib qw(lib t);

use Test::More tests => 36;

use MIME::Types;
my $a = MIME::Types->new;
ok(defined $a);

my $t = $a->type('multipart/mixed');
isa_ok($t, 'MIME::Type');
is($t->type, 'multipart/mixed');

# No extensions, but a known, explicit encoding.
$t = $a->type('message/external-body');
ok(not $t->extensions);
is($t->encoding, '8bit');

$t = $a->type('TEXT/x-RTF');
is($t->type, 'text/rtf');

my $m = $a->mimeTypeOf('gif');
ok(defined $m);
isa_ok($m, 'MIME::Type');
is($m->type, 'image/gif');

my $n = $a->mimeTypeOf('GIF');
ok(defined $n);
is($n->type, 'image/gif');

my $p = $a->mimeTypeOf('my_image.gif');
ok(defined $p);
is($p->type, 'image/gif');

my $q = $a->mimeTypeOf('windows.doc');
if($^O eq 'VMS')
{   # See MIME::Types, OS Exceptions
    is($q->type, 'text/plain');
}
else
{   is($q->type, 'application/msword');
}
is($a->mimeTypeOf('my.lzh')->type, 'application/x-lzh');

my $warn;
my $r2 = MIME::Type->new(type => 'text/x-fake2');
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r2);
}
ok(not defined $warn);

undef $warn;
my $r3 = MIME::Type->new(type => 'x-appl/x-fake3');
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r3);
}
ok(not defined $warn);

undef $warn;
my $r4 = MIME::Type->new(type => 'x-appl/fake4');
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r4);
}
ok(not defined $warn);

my $r5a = MIME::Type->new(type => 'some/vnd.vendor');
my $r5b = MIME::Type->new(type => 'some/prs.personal');
my $r5c = MIME::Type->new(type => 'some/x.experimental');

ok(!$r4 ->isVendor, 'is vendor');
ok( $r5a->isVendor);
ok(!$r5b->isVendor);
ok(!$r5c->isVendor);

ok(!$r4 ->isPersonal, 'is personal');
ok(!$r5a->isPersonal);
ok( $r5b->isPersonal);
ok(!$r5c->isPersonal);

ok(!$r4 ->isExperimental, 'is experimental');
ok(!$r5a->isExperimental);
ok(!$r5b->isExperimental);
ok( $r5c->isExperimental);

my $r6 = $a->type('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
ok($r6, 'type document');
ok($r6->isBinary);
ok(!$r6->isText);

my $r7 = $a->type('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
ok($r7, 'type sheet');
ok($r7->isBinary);
ok(!$r7->isText);
