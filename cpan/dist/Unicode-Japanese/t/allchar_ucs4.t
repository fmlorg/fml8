#!/usr/bin/perl
#
# ucs2 <=> utf8 全文字チェック
#   ucs2(0x0000..0xFFFF) => utf8
#   utf8(0x000000..0xFFFFFF) => ucs2
#

use Test::More;
BEGIN
{
	if( !$ENV{ALLCHAR_TEST} )
	{
		plan skip_all => "no ALLCHAR_TEST";
		exit;
	}
    plan 'no_plan'; #tests => 0x0010_FFFF * 4;
}

use strict;
use Unicode::Japanese;

use lib '.', 't';
require 'esc.pl';

test1();
test2();
test3();
test4();
test5();

sub test1
{
  my $xs = Unicode::Japanese->new();
  my $pp = Unicode::Japanese::PurePerl->new();
  for my $i (0..0x7f)
  {
    my $hex  = sprintf('%02x', $i);
    my $ucs4 = pack("N", $i);
    my $utf8 = pack("C*", $i);

    $xs->set($utf8, 'utf8');
    $pp->set($utf8, 'utf8');
    is(escfull($xs->ucs4), escfull($ucs4), "[1/$hex] utf8->ucs4 (xs)");
    is(escfull($pp->ucs4), escfull($ucs4), "[1/$hex] utf8->ucs4 (pp)");

    $xs->set($ucs4, 'ucs4');
    $pp->set($ucs4, 'ucs4');
    is(escfull($xs->utf8), escfull($utf8), "[1/$hex] ucs4->utf8 (xs)");
    is(escfull($pp->utf8), escfull($utf8), "[1/$hex] ucs4->utf8 (pp)");
  }
}

sub test2
{
  my $xs = Unicode::Japanese->new();
  my $pp = Unicode::Japanese::PurePerl->new();
  my $min =  0x80;
  my $max = 0x800-1;
  my $wholetest = $ENV{ALLCHAR_TEST}>=2;
  my $_max = $wholetest ? $max : $min+1;
  for my $_i ($min..$_max)
  {
    my $i = $wholetest ? $_i : ($_i==$min ? $min : $max);
    my $hex  = sprintf('%02x', $i);
    my $ucs4 = pack("N", $i);
    my $utf8 = pack("C*", 0xc0+($i>>6), map{(($i>>$_)&0x3f)^0x80} (0));

    $xs->set($utf8, 'utf8');
    $pp->set($utf8, 'utf8');
    #diag(escfull($ucs4).', '.escfull($utf8));
    is(escfull($xs->ucs4), escfull($ucs4), "[2/$hex] utf8->ucs4 (xs)");
    is(escfull($pp->ucs4), escfull($ucs4), "[2/$hex] utf8->ucs4 (pp)");

    $xs->set($ucs4, 'ucs4');
    $pp->set($ucs4, 'ucs4');
    is(escfull($xs->utf8), escfull($utf8), "[2/$hex] ucs4->utf8 (xs)");
    is(escfull($pp->utf8), escfull($utf8), "[2/$hex] ucs4->utf8 (pp)");
  }
}

sub test3
{
  my $xs = Unicode::Japanese->new();
  my $pp = Unicode::Japanese::PurePerl->new();
  my $min =    0x800;
  my $max = 0x1_0000-1;
  my $wholetest = $ENV{ALLCHAR_TEST}>=2;
  my $_max = $wholetest ? $max : $min+1;
  for my $_i ($min..$_max)
  {
    my $i = $wholetest ? $_i : ($_i==$min ? $min : $max);
    my $hex  = sprintf('%02x', $i);
    my $ucs4 = pack("N", $i);
    my $utf8 = pack("C*", 0xe0+($i>>12), map{(($i>>$_)&0x3f)^0x80} (6, 0));

    $xs->set($utf8, 'utf8');
    $pp->set($utf8, 'utf8');
    #diag(escfull($ucs4).', '.escfull($utf8));
    is(escfull($xs->ucs4), escfull($ucs4), "[3/$hex] utf8->ucs4 (xs)");
    is(escfull($pp->ucs4), escfull($ucs4), "[3/$hex] utf8->ucs4 (pp)");

    $xs->set($ucs4, 'ucs4');
    $pp->set($ucs4, 'ucs4');
    is(escfull($xs->utf8), escfull($utf8), "[3/$hex] ucs4->utf8 (xs)");
    is(escfull($pp->utf8), escfull($utf8), "[3/$hex] ucs4->utf8 (pp)");
  }
}

sub test4
{
  my $xs = Unicode::Japanese->new();
  my $pp = Unicode::Japanese::PurePerl->new();
  my $min =  0x1_0000;
  my $max = 0x11_0000-1;
  my $wholetest = $ENV{ALLCHAR_TEST}>=2;
  my $_max = $wholetest ? $max : $min+1;
  for my $_i ($min..$_max)
  {
    my $i = $wholetest ? $_i : ($_i==$min ? $min : $max);
    my $hex  = sprintf('%02x', $i);
    my $ucs4 = pack("N", $i);
    my $utf8 = pack("C*", 0xf0+($i>>18), map{(($i>>$_)&0x3f)^0x80} (12, 6, 0));

    $xs->set($utf8, 'utf8');
    $pp->set($utf8, 'utf8');
    #diag(escfull($ucs4).', '.escfull($utf8));
    is(escfull($xs->ucs4), escfull($ucs4), "[4/$hex] utf8->ucs4 (xs)");
    is(escfull($pp->ucs4), escfull($ucs4), "[4/$hex] utf8->ucs4 (pp)");

    $xs->set($ucs4, 'ucs4');
    $pp->set($ucs4, 'ucs4');
    is(escfull($xs->utf8), escfull($utf8), "[4/$hex] ucs4->utf8 (xs)");
    is(escfull($pp->utf8), escfull($utf8), "[4/$hex] ucs4->utf8 (pp)");
  }
}

sub test5
{
  my $xs = Unicode::Japanese->new();
  my $pp = Unicode::Japanese::PurePerl->new();
  for my $i (0x11_0000)
  {
    my $hex  = sprintf('%02x', $i);
    my $ucs4 = pack("N", $i);
    my $utf8 = pack("C*", 0xf0+($i>>18), map{(($i>>$_)&0x3f)^0x80} (12, 6, 0));

    $xs->set($utf8, 'utf8');
    $pp->set($utf8, 'utf8');
    #diag(escfull($ucs4).', '.escfull($utf8));
    is(escfull($xs->ucs4), escfull("\0\0\0?"), "[5/$hex] utf8->ucs4='?' (xs)");
    is(escfull($pp->ucs4), escfull("\0\0\0?"), "[5/$hex] utf8->ucs4='?' (pp)");

    $xs->set($ucs4, 'ucs4');
    $pp->set($ucs4, 'ucs4');
    is(escfull($xs->utf8), escfull('?'), "[5/$hex] ucs4->utf8='?' (xs)");
    is(escfull($pp->utf8), escfull('?'), "[5/$hex] ucs4->utf8='?' (pp)");
  }
}

