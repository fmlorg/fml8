#!/usr/bin/perl

use Test;
BEGIN{ plan tests => 5*5; }

use strict;
use Unicode::Japanese;

print STDERR $Unicode::Japanese::PurePerl?"PurePerl mode\n":"XS mode\n";

# test(code,
#      ucs4, sjis, imode, jsky, doti );
#  code: imode|jsky|doti
#
#

# imode³¨Ê¸»ú¤Î¥Æ¥¹¥È
# 
test( 'imode', # À²¤ì
      0x0FF89F, '?',"\xF8\x9F", "\e\$Gj\x0f", "\xF0\xE5" );
test( 'imode', # ÆŞ¤ê
      0x0FF8A0, '?',"\xF8\xA0", "\e\$Gi\x0f", "\xF0\xE6" );
test( 'imode', # ±«
      0x0FF8A1, '?',"\xF8\xA1", "\e\$Gk\x0f", "\xF0\xE7" );
test( 'imode', # Àã
      0x0FF8A2, '?',"\xF8\xA2", "\e\$Gh\x0f", "\xF0\xE8" );
test( 'imode', # Íë
      0x0FF8A3, '?',"\xF8\xA3", "\e\$E]\x0f", "\xF0\xE9" );

sub test
{
  my $code  = shift;
  my $ucs4  = shift;
  my $sjis  = shift;
  my $imode = shift;
  my $jsky  = shift;
  my $doti  = shift;

  $sjis  = '&#'.$ucs4.';' unless( defined($sjis) );
  $imode = '&#'.$ucs4.';' unless( defined($imode) );
  $jsky  = '&#'.$ucs4.';' unless( defined($jsky) );
  $doti  = '&#'.$ucs4.';' unless( defined($doti) );
  $ucs4 = pack('N',$ucs4);
  
  my $str = $code eq 'imode' ? Unicode::Japanese->new($imode,'sjis-imode') :
            $code eq 'jsky'  ? Unicode::Japanese->new($imode,'sjis-jsky')  :
            $code eq 'doti'  ? Unicode::Japanese->new($imode,'sjis-doti')  :
	    die "code invalid [$code]";
  
  ($ucs4,$sjis,$imode,$jsky,$doti) = escl($ucs4,$sjis,$imode,$jsky,$doti);

  # in => ucs4
  ok(esc($str->ucs4()),$ucs4,"$code=>ucs4");

  # ucs4 => others
  ok(esc($str->sjis()),      $sjis, "$code=>ucs4=>sjis" );
  ok(esc($str->sjis_imode()),$imode,"$code=>ucs4=>imode");
  ok(esc($str->sjis_jsky()), $jsky, "$code=>ucs4=>jsky" );
  ok(esc($str->sjis_doti()), $doti, "$code=>ucs4=>doti" );
}

sub escl
{
  map{esc($_)}@_;
}
sub esc
{
  my $str = shift;
  $str =~ s/\\/\\\\/g;
  $str =~ s/\n/\\n/g;
  $str =~ s/\e/\\e/g;
  $str =~ s/\r/\\r/g;
  $str =~ s/([\x00-\x1f])/'\x'.unpack("H*",$1)/ge;
  $str;
}
