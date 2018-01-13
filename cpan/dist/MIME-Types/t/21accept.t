#!/usr/bin/env perl
#
# Test httpAccept()
#

use strict;
use warnings;

use Test::More tests => 9;

use lib qw(lib t);

use MIME::Types;

my $a = MIME::Types->new;
ok(defined $a);

# simpelest case
my @t1 = $a->httpAccept('text/html');
cmp_ok(scalar @t1, '==', 1, 'simpelest case');
is($t1[0], 'text/html');

# more than one
my @t2 = $a->httpAccept('text/html, text/aap, text/noot');
cmp_ok(scalar @t2, '==', 3, 'more than one');
is($t2[0], 'text/html', 'order must be kept');
is($t2[1], 'text/aap');
is($t2[2], 'text/noot');

# with quality

my @t3 = $a->httpAccept('*/*, text/*,text/aap, text/noot;q=3, text/mies;q=0.1');
cmp_ok(scalar @t3, '==', 5, 'quality');
is(join('#',@t3), 'text/noot#text/aap#text/*#*/*#text/mies');


