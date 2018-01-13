#!/usr/bin/env perl
#
# Test exported interface.
# Tests originally by Jeff Okamato
#

use Test::More;
use strict;

use lib qw(. t);

BEGIN {plan tests => 40}

use MIME::Types;

#
# These tests assume you want an array returned
#

my ($mt, $cte) = MIME::Types::by_suffix("Pdf");
is($mt, "application/pdf");
is($cte, "base64");

($mt, $cte) = MIME::Types::by_suffix("foo.Pdf");
is($mt, "application/pdf");
is($cte, "base64");

($mt, $cte) = MIME::Types::by_suffix("flurfl");
is($mt, "");
is($cte, "");

#pkcs7-mime          p7m,p7c

my @c = MIME::Types::by_mediatype("pkcs7-mime");
cmp_ok(scalar @c, '==', 2);
cmp_ok(scalar @{$c[0]}, '>', 2);
is($c[0]->[0], "p7m");
is($c[0]->[1], "application/pkcs7-mime");
is($c[0]->[2], "base64");
cmp_ok(scalar @{$c[1]}, '>', 2);
is($c[1]->[0], "p7c");
is($c[1]->[1], "application/pkcs7-mime");
is($c[1]->[2], "base64");

@c = MIME::Types::by_mediatype("Application/pDF");
cmp_ok(scalar @c, '<', 2);
cmp_ok(scalar @{$c[0]}, '==', 3);
is($c[0]->[0], "pdf");
is($c[0]->[1], "application/pdf");
is($c[0]->[2], "base64");

@c = MIME::Types::by_mediatype("e");
cmp_ok(scalar @c, '>', 1);

@c = MIME::Types::by_mediatype("xyzzy");
cmp_ok(scalar @c, '==', 0);

#
# These tests assume you want an array reference returned
#

my $aref = MIME::Types::by_suffix("Pdf");
is($aref->[0], "application/pdf");
is($aref->[1], "base64");

$aref = MIME::Types::by_suffix("foo.Pdf");
is($aref->[0], "application/pdf");
is($aref->[1], "base64");

$aref = MIME::Types::by_suffix("flurfl");
is($aref->[0], "");
is($aref->[1], "");

$aref = MIME::Types::by_mediatype(qr!/zip!);
cmp_ok(scalar @$aref, '==', 1);
#use Data::Dumper;
#warn Dumper $aref;
is($aref->[0]->[0], "zip");
is($aref->[0]->[1], "application/zip");
is($aref->[0]->[2], "base64");

$aref = MIME::Types::by_mediatype("Application/pDF");
cmp_ok(scalar @$aref, '==', 1);
is($aref->[0]->[0], "pdf");
is($aref->[0]->[1], "application/pdf");
is($aref->[0]->[2], "base64");

$aref = MIME::Types::by_mediatype("e");
cmp_ok(scalar @$aref, '>', 1);

$aref = MIME::Types::by_mediatype("xyzzy");
cmp_ok(scalar @$aref, '==', 0);

$aref = MIME::Types::by_suffix("foo.tsv");
is($aref->[0], "text/tab-separated-values");
is($aref->[1], "quoted-printable");
