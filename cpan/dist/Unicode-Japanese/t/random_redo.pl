#!/usr/bin/perl

use strict;
use Unicode::Japanese;

our @charcodes = (
		  'jis', 'sjis', 'euc',
		  'sjis-imode', 'sjis-doti', 'sjis-jsky',
		 );

my $file = 'random.dat';
open(FILE,"<$file") or die "cannot open [$file]";

my $dat;
read FILE,$dat,8;
my ($count,$len)  = unpack('NN',$dat);
printf "[%#08x] len:%d\n",$count,$len;
read FILE,$dat,$len;

{
  my $src = $dat;
  
  # ------------------------------------
  # utf8 => jis/eucjp/etc.
  # 
  my $str = Unicode::Japanese->new($src,'utf8');
  foreach my $ocode ( @charcodes )
  {
    print "utf8=>$ocode...\n";
    $str->conv($ocode);
  }
  # ------------------------------------
  # jis/eucjp/etc. => utf8
  foreach my $icode ( @charcodes )
  {
    print "$icode=>utf8...\n";
    Unicode::Japanese->new($src,$icode);
  }
}

print "done\n";
