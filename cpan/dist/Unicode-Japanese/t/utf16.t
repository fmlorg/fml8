#!/usr/bin/perl
#
# utf16 check.
# * surrogate pairs.
#

use strict;
use Test;
BEGIN { plan tests => 10, };

# -----------------------------------------------------------------------------
# load module
#
use Unicode::Japanese;
my $xs = Unicode::Japanese->new();
my $pp = Unicode::Japanese::PurePerl->new();
sub utf16ToUtf8_xs($){ tt($xs->set($_[0],'utf16')->utf8()); }
sub utf16ToUtf8_pp($){ tt($pp->set($_[0],'utf16')->utf8()); }
sub utf16ToUcs4_xs($){ tt($xs->set($_[0],'utf16')->ucs4()); }
sub utf16ToUcs4_pp($){ tt($pp->set($_[0],'utf16')->ucs4()); }
sub tt($){ join(' ',map{unpack("H*",$_)}split(//,$_[0])); }
sub bin($){ $_[0]; }

# -----------------------------------------------------------------------------
# run.
#
$| = 1;

{
  # surrogate pair.(first one, U+01.0000)
  #
  my $test = "\xD8\x00\xDC\x00";
  my $correct_ucs4 = tt("\x00\x01\x00\x00");
  my $correct_utf8 = tt("\xf0\x90\x80\x80");
  ok(utf16ToUtf8_xs($test),$correct_utf8,"surrogate pair (xs/utf8)");
  ok(utf16ToUtf8_pp($test),$correct_utf8,"surrogate pair (pp/utf8)");
  ok(utf16ToUcs4_xs($test),$correct_ucs4,"surrogate pair (xs/ucs4)");
  ok(utf16ToUcs4_pp($test),$correct_ucs4,"surrogate pair (pp/ucs4)");
}
{
  # surrogate pair.(sample)
  # Western Musical Symbols, (U+01D100..)
  # U+0x01D11E, MUSICAL SYMBOL G CLEF (ト音記号)
  #
  my $test = "\xD8\x3C\xDD\x1E";
  my $correct_ucs4 = tt("\x00\x01\xF1\x1E");
  my $correct_utf8 = tt("\xF0\x9F\x84\x9E");
  ok(utf16ToUtf8_xs($test),$correct_utf8,"surrogate pair (xs)");
  ok(utf16ToUtf8_pp($test),$correct_utf8,"surrogate pair (pp)");
  ok(utf16ToUcs4_xs($test),$correct_ucs4,"surrogate pair (xs)");
  ok(utf16ToUcs4_pp($test),$correct_ucs4,"surrogate pair (pp)");
}
{
  # surrogate pair.(last one, U+10.FFFF)
  #
  my $test = "\xDB\xFF\xDF\xFF";
  my $correct = tt("\x00\x10\xFF\xFF");
  ok(utf16ToUcs4_xs($test),$correct,"surrogate pair (xs)");
  ok(utf16ToUcs4_pp($test),$correct,"surrogate pair (pp)");
}
