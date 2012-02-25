## ----------------------------------------------------------------------------
#  t/illegal.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright YMIRLINK,Inc.
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use Test::More tests => 72;
use Unicode::Japanese;

my $Z1 = "\0";                         # U+0000 in 1 byte.
my $Z2 = "\xc0\x80";                   # U+0000 in 2 bytes.
my $Z3 = "\xe0\x80\x80";               # U+0000 in 3 bytes.
my $Z4 = "\xf0\x80\x80\x80";           # U+0000 in 4 bytes.
my $Z5 = "\xf8\x80\x80\x80\x80";       # U+0000 in 5 bytes.
my $Z6 = "\xfc\x80\x80\x80\x80\x80";   # U+0000 in 6 bytes.

sub u{ unpack("H*",$_[0]) }

# -----------------------------------------------------------------------------
# internal data
#
{
  my $d = "internal data / \\x00";
  my $U = Unicode::Japanese->new();
  my $PPU = Unicode::Japanese::PurePerl->new();
  
  is(u($U->set($Z1)->{str}), u("\x00"), "$d (1 byte)");
  is(u($U->set($Z2)->{str}), u("?"),    "$d (2 bytes)");
  is(u($U->set($Z3)->{str}), u("?"),    "$d (3 bytes)");
  is(u($U->set($Z4)->{str}), u("?"),    "$d (4 bytes)");
  is(u($U->set($Z5)->{str}), u("?"),    "$d (5 bytes)");
  is(u($U->set($Z6)->{str}), u("?"),    "$d (6 bytes)");

  is(u($PPU->set($Z1)->{str}), u("\x00"), "$d (1 byte) [PP]");
  is(u($PPU->set($Z2)->{str}), u("?"),    "$d (2 bytes) [PP]");
  is(u($PPU->set($Z3)->{str}), u("?"),    "$d (3 bytes) [PP]");
  is(u($PPU->set($Z4)->{str}), u("?"),    "$d (4 bytes) [PP]");
  is(u($PPU->set($Z5)->{str}), u("?"),    "$d (5 bytes) [PP]");
  is(u($PPU->set($Z6)->{str}), u("?"),    "$d (6 bytes) [PP]");
}

# -----------------------------------------------------------------------------
# sjis
#
{
  my $d = "sjis / \\x00";
  my $U = Unicode::Japanese->new();
  my $PPU = Unicode::Japanese::PurePerl->new();
  
  $U->{str}=$Z1; is(u($U->sjis()), u("\x00"), "$d (1 byte)");
  $U->{str}=$Z2; is(u($U->sjis()), u("?"),    "$d (2 bytes)");
  $U->{str}=$Z3; is(u($U->sjis()), u("?"),    "$d (3 bytes)");
  $U->{str}=$Z4; is(u($U->sjis()), u("?"),    "$d (4 bytes)");
  $U->{str}=$Z5; is(u($U->sjis()), u("?"),    "$d (5 bytes)");
  $U->{str}=$Z6; is(u($U->sjis()), u("?"),    "$d (6 bytes)");

  $PPU->{str}=$Z1; is(u($PPU->sjis()), u("\x00"), "$d (1 byte) [PP]");
  $PPU->{str}=$Z2; is(u($PPU->sjis()), u("?"),    "$d (2 bytes) [PP]");
  $PPU->{str}=$Z3; is(u($PPU->sjis()), u("?"),    "$d (3 bytes) [PP]");
  $PPU->{str}=$Z4; is(u($PPU->sjis()), u("?"),    "$d (4 bytes) [PP]");
  $PPU->{str}=$Z5; is(u($PPU->sjis()), u("?"),    "$d (5 bytes) [PP]");
  $PPU->{str}=$Z6; is(u($PPU->sjis()), u("?"),    "$d (6 bytes) [PP]");
}

# -----------------------------------------------------------------------------
# utf8
#
{
  my $d = "utf8 / \\x00";
  my $U = Unicode::Japanese->new();
  my $PPU = Unicode::Japanese::PurePerl->new();
  
  $U->{str}=$Z1; is(u($U->utf8()), u("\x00"), "$d (1 byte)");
  $U->{str}=$Z2; is(u($U->utf8()), u("?"),    "$d (2 bytes)");
  $U->{str}=$Z3; is(u($U->utf8()), u("?"),    "$d (3 bytes)");
  $U->{str}=$Z4; is(u($U->utf8()), u("?"),    "$d (4 bytes)");
  $U->{str}=$Z5; is(u($U->utf8()), u("?"),    "$d (5 bytes)");
  $U->{str}=$Z6; is(u($U->utf8()), u("?"),    "$d (6 bytes)");

  $PPU->{str}=$Z1; is(u($PPU->utf8()), u("\x00"), "$d (1 byte) [PP]");
  $PPU->{str}=$Z2; is(u($PPU->utf8()), u("?"),    "$d (2 bytes) [PP]");
  $PPU->{str}=$Z3; is(u($PPU->utf8()), u("?"),    "$d (3 bytes) [PP]");
  $PPU->{str}=$Z4; is(u($PPU->utf8()), u("?"),    "$d (4 bytes) [PP]");
  $PPU->{str}=$Z5; is(u($PPU->utf8()), u("?"),    "$d (5 bytes) [PP]");
  $PPU->{str}=$Z6; is(u($PPU->utf8()), u("?"),    "$d (6 bytes) [PP]");
}

# -----------------------------------------------------------------------------
# ucs2
#
{
  my $d = "ucs2 / \\x00";
  my $U = Unicode::Japanese->new();
  my $PPU = Unicode::Japanese::PurePerl->new();
  
  $U->{str}=$Z1; is(u($U->ucs2()), u("\x00\x00"), "$d (1 byte)");
  $U->{str}=$Z2; is(u($U->ucs2()), u("\x00?"),    "$d (2 bytes)");
  $U->{str}=$Z3; is(u($U->ucs2()), u("\x00?"),    "$d (3 bytes)");
  $U->{str}=$Z4; is(u($U->ucs2()), u("\x00?"),    "$d (4 bytes)");
  $U->{str}=$Z5; is(u($U->ucs2()), u("\x00?"),    "$d (5 bytes)");
  $U->{str}=$Z6; is(u($U->ucs2()), u("\x00?"),    "$d (6 bytes)");

  $PPU->{str}=$Z1; is(u($PPU->ucs2()), u("\x00\x00"), "$d (1 byte) [PP]");
  $PPU->{str}=$Z2; is(u($PPU->ucs2()), u("\x00?"),    "$d (2 bytes) [PP]");
  $PPU->{str}=$Z3; is(u($PPU->ucs2()), u("\x00?"),    "$d (3 bytes) [PP]");
  $PPU->{str}=$Z4; is(u($PPU->ucs2()), u("\x00?"),    "$d (4 bytes) [PP]");
  $PPU->{str}=$Z5; is(u($PPU->ucs2()), u("\x00?"),    "$d (5 bytes) [PP]");
  $PPU->{str}=$Z6; is(u($PPU->ucs2()), u("\x00?"),    "$d (6 bytes) [PP]");
}

# -----------------------------------------------------------------------------
# ucs4
#
{
  my $d = "ucs4 / \\x00";
  my $U = Unicode::Japanese->new();
  my $PPU = Unicode::Japanese::PurePerl->new();
  
  $U->{str}=$Z1; is(u($U->ucs4()), u("\x00\x00\x00\x00"), "$d (1 byte)");
  $U->{str}=$Z2; is(u($U->ucs4()), u("\x00\x00\x00?"),    "$d (2 bytes)");
  $U->{str}=$Z3; is(u($U->ucs4()), u("\x00\x00\x00?"),    "$d (3 bytes)");
  $U->{str}=$Z4; is(u($U->ucs4()), u("\x00\x00\x00?"),    "$d (4 bytes)");
  $U->{str}=$Z5; is(u($U->ucs4()), u("\x00\x00\x00?"),    "$d (5 bytes)");
  $U->{str}=$Z6; is(u($U->ucs4()), u("\x00\x00\x00?"),    "$d (6 bytes)");

  $PPU->{str}=$Z1; is(u($PPU->ucs4()), u("\x00\x00\x00\x00"), "$d (1 byte) [PP]");
  $PPU->{str}=$Z2; is(u($PPU->ucs4()), u("\x00\x00\x00?"),    "$d (2 bytes) [PP]");
  $PPU->{str}=$Z3; is(u($PPU->ucs4()), u("\x00\x00\x00?"),    "$d (3 bytes) [PP]");
  $PPU->{str}=$Z4; is(u($PPU->ucs4()), u("\x00\x00\x00?"),    "$d (4 bytes) [PP]");
  $PPU->{str}=$Z5; is(u($PPU->ucs4()), u("\x00\x00\x00?"),    "$d (5 bytes) [PP]");
  $PPU->{str}=$Z6; is(u($PPU->ucs4()), u("\x00\x00\x00?"),    "$d (6 bytes) [PP]");
}

# -----------------------------------------------------------------------------
# utf16
#
{
  my $d = "utf16 / \\x00";
  my $U = Unicode::Japanese->new();
  my $PPU = Unicode::Japanese::PurePerl->new();
  
  $U->{str}=$Z1; is(u($U->utf16()), u("\x00\x00"), "$d (1 byte)");
  $U->{str}=$Z2; is(u($U->utf16()), u("\x00?"),    "$d (2 bytes)");
  $U->{str}=$Z3; is(u($U->utf16()), u("\x00?"),    "$d (3 bytes)");
  $U->{str}=$Z4; is(u($U->utf16()), u("\x00?"),    "$d (4 bytes)");
  $U->{str}=$Z5; is(u($U->utf16()), u("\x00?"),    "$d (5 bytes)");
  $U->{str}=$Z6; is(u($U->utf16()), u("\x00?"),    "$d (6 bytes)");

  $PPU->{str}=$Z1; is(u($PPU->utf16()), u("\x00\x00"), "$d (1 byte) [PP]");
  $PPU->{str}=$Z2; is(u($PPU->utf16()), u("\x00?"),    "$d (2 bytes) [PP]");
  $PPU->{str}=$Z3; is(u($PPU->utf16()), u("\x00?"),    "$d (3 bytes) [PP]");
  $PPU->{str}=$Z4; is(u($PPU->utf16()), u("\x00?"),    "$d (4 bytes) [PP]");
  $PPU->{str}=$Z5; is(u($PPU->utf16()), u("\x00?"),    "$d (5 bytes) [PP]");
  $PPU->{str}=$Z6; is(u($PPU->utf16()), u("\x00?"),    "$d (6 bytes) [PP]");
}

# -----------------------------------------------------------------------------
# End Of File.
# -----------------------------------------------------------------------------
