#!/usr/bin/env perl
#
# Test Mojo plugin
#

use strict;
use warnings;

use lib qw(lib t);
use Test::More;

eval "require Mojo::Base";
plan skip_all => 'Mojo probably not installed' if $@;

plan tests => 14;

require_ok('MojoX::MIME::Types');

my $m = MojoX::MIME::Types->new;
isa_ok($m, 'MojoX::MIME::Types');
isa_ok($m->mimeTypes, 'MIME::Types');

my $t = $m->types;
isa_ok($t, 'HASH', 'types table (deprecated)');
cmp_ok(keys %$t, '>', 1000, 'MIME::Types describes '.(keys %$t).' extensions');
ok(exists $t->{txt});
isa_ok($t->{txt}, 'ARRAY');
cmp_ok(@{$t->{txt}}, '==', 1);
is($t->{txt}[0], 'text/plain');

my $ext = $m->detect('text/html, application/json;q=9');
isa_ok($ext, 'ARRAY', 'detect() reports '.@$ext);
ok(grep $_ eq 'html', @$ext, 'contains html');
ok(grep $_ eq 'json', @$ext, 'contains json');

is($m->type('html'), 'text/html', 'type($ext)');

is_deeply $m->detect('image/missing'), [], 'missing type';
