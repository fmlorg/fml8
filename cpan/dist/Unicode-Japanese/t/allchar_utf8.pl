#!/usr/bin/perl

use strict;
use Unicode::Japanese;

# とりあえず utf8=>* 変換してみるだけ.
# あってるかはみてないにゃ.
# ３文字しかしてなかったり…
# utf8は６文字まで？
#

our @charcodes = (
		  'jis', 'sjis', 'euc',
		  'sjis-imode', 'sjis-doti', 'sjis-jsky',
		 );

# in: utf8 0x00 - 0xFF.FF.FF

$| = 1;
for( my $i=0; $i<=0xFFFFFF; ++$i )
{
  if( ($i&0xFF)==0 )
  {
    if( ($i&0x3FFF)==0 )
    {
      print "\n" if( $i );
      printf "[%#08x]",$i;
    }else
    {
      print ".";
    }
  }
  
  my $src = pack('N',$i);
  $src =~ s/^\0+//;

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

print "\n";

check_mem();
sub check_mem
{
  open FILE,"/proc/$$/status" or die "cannot open [/proc/$$/status]";
  while(<FILE>)
  {
    m/^Vm\w+:\s*(\d+)/m and print;
  }
  close FILE;
}
