#!/usr/bin/perl
#
# ucs2 <=> utf8 全文字チェック
#   ucs2(0x0000..0xFFFF) => utf8
#   utf8(0x000000..0xFFFFFF) => ucs2
#

use strict;
use Unicode::Japanese;

$| = 1;

# ucs2 => utf8
print "ucs2 => utf8\n";
print "[0x000000]";
for( my $i=0; $i<=0xFFFF; ++$i )
{
  if( ($i&0xFF)==0 && $i )
  {
    if( ($i&0x3FFF)==0 )
    {
      printf "\n[%#08x]",$i;
    }else
    {
      print ".";
    }
  }

  my $src = pack('n',$i);

  my $str  = Unicode::Japanese->new($src,'ucs2');
  my $xs   = $str->utf8();
  my $orig = _ucs2_utf8($str,$src);
  if( $xs ne $orig )
  {
    $src  = unpack('H*',$src);
    $xs   = unpack('H*',$xs);
    $orig = unpack('H*',$orig);
    print "\n";
    die "not match, src:[$src], xs:[$xs] != orig:[$orig]";
  }
}
print "\n";

# utf8 => ucs2
print "utf8 => ucs2\n";
print "[0x000000]";
for( my $i=0; $i<=0xFFFFFF; ++$i )
{
  if( ($i&0xFF)==0 && $i )
  {
    if( ($i&0x3FFF)==0 )
    {
      printf "\n[%#08x]",$i;
    }else
    {
      print ".";
    }
  }

  my $src = pack('N',$i);
  $src =~ s/^\0+//;
  
  my $str  = Unicode::Japanese->new($src,'utf8');
  my $xs   = $str->ucs2();
  my $orig = _utf8_ucs2($str,$src);
  if( $xs ne $orig )
  {
    $src  = unpack('H*',$src);
    $xs   = unpack('H*',$xs);
    $orig = unpack('H*',$orig);
    print "\n";
    die "not match, src:[$src], xs:[$xs] != orig:[$orig]";
  }
}
print "\n";


# ----------------------------------------------------------------------

my @U2T;
my %T2U;

sub _ucs2_utf8 {
  my $this = shift;
  my $str = shift;
  
  if(!defined($str))
    {
      return '';
    }
  
  my $result = '';
  for my $uc (unpack("n*", $str))
    {
      $result .= $U2T[$uc] ? $U2T[$uc] :
	($U2T[$uc] = ($uc < 0x80) ? chr($uc) :
	  ($uc < 0x800) ? chr(0xC0 | ($uc >> 6)) . chr(0x80 | ($uc & 0x3F)) :
	    chr(0xE0 | ($uc >> 12)) . chr(0x80 | (($uc >> 6) & 0x3F)) .
	      chr(0x80 | ($uc & 0x3F)));
    }
  
  $result;
}

sub _utf8_ucs2 {
  my $this = shift;
  my $str = shift;
  
  if(!defined($str))
    {
      return '';
    }

  my $c1;
  my $c2;
  my $c3;
  $str =~ s/([\x00-\x7f]|[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf7][\x80-\xbf]{3}|[\xf8-\xfb][\x80-\xbf]{4}|[\xfc-\xfd][\x80-\xbf]{5}|(.))/
    defined($2)?"\0$2":
    $T2U{$1}
      or ($T2U{$1}
	  = ((length($1) == 1) ? pack("n", unpack("C", $1)) :
	     (length($1) == 2) ? (($c1,$c2) = unpack("C2", $1),
				  pack("n", (($c1 & 0x1F)<<6)|($c2 & 0x3F))) :
	     (length($1) == 3) ? (($c1,$c2,$c3) = unpack("C3", $1),
				  pack("n", (($c1 & 0x0F)<<12)|(($c2 & 0x3F)<<6)|($c3 & 0x3F))) : "\0?"))
	/eg;
  $str;
}
