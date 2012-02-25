#! /usr/bin/perl -w
# $Id$
use strict;
use Test::More tests => 2;

use Unicode::Japanese;

# JIS, HANKAKU-KATAKANA, "TE SU TO"
my $txt = "\e(IC=D\e(B";

Unicode::Japanese->new(); # load dyncode.
is( Unicode::Japanese->getcode($txt), "jis", "getcode(xs): jis");
is( Unicode::Japanese::PurePerl->getcode($txt), "jis", "getcode(pp): jis");
