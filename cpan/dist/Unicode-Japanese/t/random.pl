#!/usr/bin/perl
#
# t/random.pl
#
# ランダムに作成した文字列(バイナリ列)をいろいろ変換.
#
# $ sh runtest.sh t/random.pl > random.out
# 
# 異常終了時には
# $ sh runtest.sh t/random_redo.pl
# でリトライできます.
# 
use strict;
use Unicode::Japanese;

my $maxlen = 512;

our @charcodes = (
		  'jis', 'sjis', 'euc',
		  'sjis-imode', 'sjis-doti', 'sjis-jsky',
		 );

our $count = 0;

my $file = 'random.dat';
open(FILE,">$file") or die "cannot open [$file]";
select((select(FILE),$|=1)[0]);

$| = 1;
print "[0x000000]";

for(;; ++$count)
{
  if( ($count&0xFF)==0 && $count )
  {
    if( ($count&0x3FFF)==0 )
    {
      printf "\n[%#08x]",$count;
    }else
    {
      print ".";
    }
  }
  
  my $len = int(rand($maxlen-4))+4;
  my $src = '';
  for( my $i=0; $i<$len; ++$i )
  {
    $src .= pack('C',int(rand(0x256)));
  }

  seek FILE,0,0;
  print FILE pack('N',$count);
  print FILE pack('N',length($src));
  print FILE $src;
  truncate FILE,length($src)+8;

  # ------------------------------------
  # utf8 => jis/eucjp/etc.
  # 
  my $str = Unicode::Japanese->new($src,'utf8');
  foreach my $ocode ( @charcodes )
  {
    $str->conv($ocode);
  }
  # ------------------------------------
  # jis/eucjp/etc. => utf8
  foreach my $icode ( @charcodes )
  {
    Unicode::Japanese->new($src,$icode);
  }
}
