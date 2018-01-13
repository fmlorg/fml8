#!/usr/bin/env perl
#
# Test httpAcceptBest and httpAcceptSelect()
#

use strict;
use warnings;

use Test::More tests => 25;

use lib qw(lib t);

use MIME::Types;

my $mt = MIME::Types->new;
ok(defined $mt);

my @have = map $mt->type($_), qw[text/plain text/html application/pdf];
cmp_ok(scalar @have, '==', 3, 'create offers');
isa_ok($_, 'MIME::Type') for @have;

ok($have[0]->equals('text/plain'), 'equal');
ok(!$have[0]->equals('text/html'), 'not equal');

# remember that order is important
my $t0 = $mt->httpAcceptBest(['text/plain'], @have);
is($t0, 'text/plain', 'single');

my $t1 = $mt->httpAcceptBest(['text/plain', 'text/html'], @have);
is($t1, 'text/plain', 'first');

my $t2 = $mt->httpAcceptBest(['text/html', 'text/plain'], @have);
is($t2, 'text/html', 'second');

my $t3 = $mt->httpAcceptBest(['text/xyz', 'text/plain'], @have);
is($t3, 'text/plain', 'second2');

my $t4 = $mt->httpAcceptBest('text/html, application/pdf', @have);
is($t4, 'text/html', 'string');



### Select()

is($mt->mimeTypeOf('txt'), 'text/plain', 'test mimeTypeOf');
is($mt->mimeTypeOf('a.txt'), 'text/plain');

my ($f0, $m0) = $mt->httpAcceptSelect(undef, ['a.txt', 'a.html']);
is($f0, 'a.txt', 'no Accept, take first');
isa_ok($m0, 'MIME::Type');
is("$m0", 'text/plain');

my ($f1, $m1)
   = $mt->httpAcceptSelect('text/plain, text/html', ['a.txt', 'a.html']);
is($f1, 'a.txt', 'select text');
isa_ok($m1, 'MIME::Type');
is("$m1", 'text/plain');

my ($f2, $m2)
   = $mt->httpAcceptSelect('text/html, text/plain', ['a.txt', 'a.html']);
is($f2, 'a.html', 'select html');
isa_ok($m2, 'MIME::Type');
is("$m2", 'text/html');

my ($f3, $m3)
   = $mt->httpAcceptSelect('text/html, text/plain', ['a.pdf', 'a.docx']);
ok(!defined $f3, 'not accepted');
ok(!defined $m3);
