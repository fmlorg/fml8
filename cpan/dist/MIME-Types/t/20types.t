#!/usr/bin/perl -w
#
# Test reporting warnings, errors and family.
#

use Test;
use strict;

use lib qw(. t);

BEGIN {plan tests => 19}

use MIME::Types;

my $a = MIME::Types->new;
ok($a);

my @t = $a->type('multipart/mixed');
ok(@t==1);
my $t = $t[0];
ok(ref $t eq 'MIME::Type');
ok($t->type eq 'multipart/mixed');

@t = $a->type('TEXT/x-RTF');
ok(@t==1);
$t = $t[0];
ok($t->type eq 'text/rtf');

my $m = $a->mimeTypeOf('gif');
ok($m);
ok(ref $m eq 'MIME::Type');
ok($m->type eq 'image/gif');

my $n = $a->mimeTypeOf('GIF');
ok($n);
ok($n->type eq 'image/gif');

my $p = $a->mimeTypeOf('my_image.gif');
ok($p);
ok($p->type eq 'image/gif');

my $q = $a->mimeTypeOf('windows.doc');
ok($q->type eq 'application/msword');
ok($a->mimeTypeOf('my.lzh')->type eq 'application/octet-stream');

my $r1 = MIME::Type->new(type => 'text/fake1');
my $warn;
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r1);
}
ok($warn =~ m/report/);

undef $warn;
my $r2 = MIME::Type->new(type => 'text/x-fake2');
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r2);
}
ok(!defined $warn);

undef $warn;
my $r3 = MIME::Type->new(type => 'x-appl/x-fake3');
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r3);
}
ok(!defined $warn);

undef $warn;
my $r4 = MIME::Type->new(type => 'x-appl/fake4');
{   $SIG{__WARN__} = sub {$warn = join '',@_};
    $a->addType($r4);
}
ok(!defined $warn);
