#!/usr/bin/perl -w
#
# Test exported interface.
# Tests originally by Jeff Okamato
#

use Test;
use strict;

use lib qw(. t);

BEGIN {plan tests => 34}

use MIME::Types;

#
# These tests assume you want an array returned
#

my ($mt, $cte) = MIME::Types::by_suffix("Pdf");
ok($mt eq "application/pdf");
ok($cte eq "base64");

($mt, $cte) = MIME::Types::by_suffix("foo.Pdf");
ok($mt eq "application/pdf");
ok($cte eq "base64");

($mt, $cte) = MIME::Types::by_suffix("flurfl");
ok($mt eq "");
ok($cte eq "");

my @c = MIME::Types::by_mediatype("pdF");
ok(@c == 1);
ok($c[0]->[0] eq "pdf");
ok($c[0]->[1] eq "application/pdf");
ok($c[0]->[2] eq "base64");

@c = MIME::Types::by_mediatype("Application/pDF");
ok(@c == 1);
ok($c[0]->[0] eq "pdf");
ok($c[0]->[1] eq "application/pdf");
ok($c[0]->[2] eq "base64");

@c = MIME::Types::by_mediatype("e");
ok(@c > 1);

@c = MIME::Types::by_mediatype("xyzzy");
ok(@c == 0);

#
# These tests assume you want an array reference returned
#

my $aref = MIME::Types::by_suffix("Pdf");
ok($aref->[0] eq "application/pdf");
ok($aref->[1] eq "base64");

$aref = MIME::Types::by_suffix("foo.Pdf");
ok($aref->[0] eq "application/pdf");
ok($aref->[1] eq "base64");

$aref = MIME::Types::by_suffix("flurfl");
ok($aref->[0] eq "");
ok($aref->[1] eq "");

$aref = MIME::Types::by_mediatype("pdF");
ok(@$aref == 1);
ok($aref->[0]->[0] eq "pdf");
ok($aref->[0]->[1] eq "application/pdf");
ok($aref->[0]->[2] eq "base64");

$aref = MIME::Types::by_mediatype("Application/pDF");
ok(@$aref == 1);
ok($aref->[0]->[0] eq "pdf");
ok($aref->[0]->[1] eq "application/pdf");
ok($aref->[0]->[2] eq "base64");

$aref = MIME::Types::by_mediatype("e");
ok(@$aref > 1);

$aref = MIME::Types::by_mediatype("xyzzy");
ok(@$aref == 0);

$aref = MIME::Types::by_suffix("foo.tsv");
ok($aref->[0] eq "text/tab-separated-values");
ok($aref->[1] eq "quoted-printable");
