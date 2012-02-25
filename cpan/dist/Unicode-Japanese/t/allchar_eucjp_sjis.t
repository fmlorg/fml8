#!/usr/bin/perl -w

use Test::More;
BEGIN
{
	if( !$ENV{ALLCHAR_TEST} )
	{
		plan skip_all => "no ALLCHAR_TEST";
		exit;
	}
    plan
	tests =>
	    0x100 # 1byte
	    + (0xfe-0xa1+1)**2 # EUCJP_0212
	    + (0xfe-0xa1+1)**2 # EUCJP_C
	    + (0xdf-0xa1+1); # EUCJP_KANA
}

use strict;
use Unicode::Japanese;

my %RE =
    (
     ASCII     => '[\x00-\x7f]',
     EUC_0212  => '\x8f[\xa1-\xfe][\xa1-\xfe]',
     EUC_C     => '[\xa1-\xfe][\xa1-\xfe]',
     EUC_KANA  => '\x8e[\xa1-\xdf]',
    );
    my $RE = join('|',values(%RE));
Unicode::Japanese->new();

for( my $i=0; $i<0x100; ++$i )
{
  my $ch = pack('C',$i);
  my $valid = $ch;
  my $res = Unicode::Japanese->_e2s($ch);
  is($res,$valid,sprintf("ascii:0x%02x",$i) );
  if( $valid ne $res )
  {
    out('1byte-char',$ch,$res,$valid);
  }
}

# EUCJP_0212
for( my $c1 = 0xa1; $c1<=0xfe; ++$c1 )
{
  for( my $c2 = 0xa1; $c2<=0xfe; ++$c2 )
  {
    my $ch = "\x8f".pack("CC",$c1,$c2);
    my $valid = "\x81\xac"; # udnef-sjis
    my $res = Unicode::Japanese->_e2s($ch);
    is($res,$valid,sprintf("eucjp_0212:0x%02x%02x",$c1,$c2));
    if( $res ne $valid )
    {
      out('EUCJP_0212',$ch,$res,$valid);
    }
  }
}

# EUCJP_C
for( my $c1 = 0xa1; $c1<=0xfe; ++$c1 )
{
  for( my $c2 = 0xa1; $c2<=0xfe; ++$c2 )
  {
    my $ch = pack("CC",$c1,$c2);
    my $valid = conv($ch);
    my $res = Unicode::Japanese->_e2s($ch);
    is($res,$valid,sprintf("eucjp_0212:0x%02x%02x",$c1,$c2));
    if( $res ne $valid )
    {
      out('EUCJP_C',$ch,$res,$valid);
    }
  }
}

# EUCJP_KANA
for( my $c1 = 0xa1; $c1<=0xdf; ++$c1 )
{
  my $ch = "\x8e".pack("C",$c1);
  my $valid = pack("C",$c1);
  my $res = Unicode::Japanese->_e2s($ch);
  is($res,$valid,sprintf("eucjp_kana:0x%02x",$c1));
  if( $res ne $valid )
  {
    out('EUCJP_KANA',$ch,$res,$valid);
  }
}

sub conv
{
  my $ch = shift;
  #`echo -n '$ch'|nkf -E -s`;
  use Jcode;
  #Jcode::euc_sjis($ch);
  Jcode->new($ch,"euc")->sjis;
}

sub out
{
  my $where = shift;
  my $ch = shift;
  my $res = shift;
  my $valid = shift;

  if(0)
  {
  print STDERR "[$where]\n";
  print STDERR "char :", (map{sprintf(" %02x",$_)} unpack('C*',$ch)),"\n";
  print STDERR "res  :", (map{sprintf(" %02x",$_)} unpack('C*',$res)),"\n";
  print STDERR "valid:", (map{sprintf(" %02x",$_)} unpack('C*',$valid)),"\n";
  }
  #exit;
}
