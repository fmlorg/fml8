#!/usr/bin/env perl
#
# Test overloading on MIME::Type objects.
#

use strict;
use warnings;

use lib qw(lib t);

use Test::More tests => 21;

use MIME::Type;

my $a = MIME::Type->new(type => 'x-appl/x-zip');
my $b = MIME::Type->new(type => 'appl/x-zip');
my $c = MIME::Type->new(type => 'x-appl/zip');
my $d = MIME::Type->new(type => 'appl/zip');
my $e = MIME::Type->new(type => 'text/plain');

ok($a eq $b);
ok($a eq $c);
ok($a eq $d);
ok($b eq $c);
ok($b eq $d);
ok($c eq $d);
ok($a ne $e);

ok(!$a->isRegistered);
ok(!$b->isRegistered);
ok(!$c->isRegistered);
ok( $d->isRegistered);
ok( $e->isRegistered);

is("$a", 'x-appl/x-zip');
is("$b", 'appl/x-zip');
is("$c", 'x-appl/zip');
is("$d", 'appl/zip');
is("$e", 'text/plain');

ok($a eq 'appl/zip');
ok($b eq 'APPL/ZIP');
ok($c eq 'x-appl/x-zip');
ok($e eq 'text/plain');
