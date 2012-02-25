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
	    0x100 # 1byte, SJIS_KANA
	    + (0x9f-0x81+1+0xef-0xe0+1)*(0x7e-0x40+1+0xfc-0x80+1); # SJIS_C
}

use strict;
use Unicode::Japanese;

my %RE =
    (
     ASCII     => '[\x00-\x7f]',
     SJIS_C    => '[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc]',
     SJIS_KANA => '[\xa1-\xdf]',
    );
    my $RE = join('|',values(%RE));
Unicode::Japanese->new();

for( my $i=0; $i<0x100; ++$i )
{
  my $ch = pack('C',$i);
  my $kana = $ch=~/^($RE{SJIS_KANA})$/;
  my $valid = $kana ? "\x8e".$ch : $ch ;
  my $res = Unicode::Japanese->_s2e($ch);
  is($res,$valid);
  if( $valid ne $res )
  {
    my $where = $kana ? 'SJIS_KANA' : '1byte-char';
    out($where,$ch,$res,$valid);
  }
}

# SJIS_C
for( my $c1 = 0x81; $c1<=0xef; ++$c1 )
{
  $c1 = 0xe0 if( $c1==0xa0 );
  for( my $c2 = 0x40; $c2<=0xfc; ++$c2 )
  {
    $c2 = 0x80 if( $c2==0x7f );
    my $ch = pack("CC",$c1,$c2);
    my $valid = conv($ch);
    my $res = Unicode::Japanese->_s2e($ch);
    is($res,$valid);
    if( $res ne $valid )
    {
      out('SJIS_C',$ch,$res,$valid);
    }
  }
}

sub conv
{
  my $ch = shift;
  #`echo -n '$ch'|nkf -S -e`;
  use Jcode;
  Jcode::sjis_euc($ch);
}

sub out
{
  my $where = shift;
  my $ch = shift;
  my $res = shift;
  my $valid = shift;

  print STDERR "[$where]\n";
  print STDERR "char :", (map{sprintf(" %02x",$_)} unpack('C*',$ch)),"\n";
  print STDERR "res  :", (map{sprintf(" %02x",$_)} unpack('C*',$res)),"\n";
  print STDERR "valid:", (map{sprintf(" %02x",$_)} unpack('C*',$valid)),"\n";
  exit;
}
