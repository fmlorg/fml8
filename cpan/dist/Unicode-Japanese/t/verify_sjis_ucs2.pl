#!/usr/bin/perl -w
#
# t/verify_sjis_ucs2.pl
#
# sjis=>ucs2とucs2=>sjisの全文字テスト
# XS側だけのてすと….
#
# $ sh runtest.sh t/verify_sjis_ucs2.pl
# 
# all sjis(0x0000-0xFFFF) => ucs2
# all ucs2(0x0000-0xFFFF) => sjis
#

use strict;
#BEGIN{$Unicode::Japanese::PurePerl = 1;}
use Unicode::Japanese;
use IO::File;

print "loading Uni::Jp\n";
Unicode::Japanese->new('');
my $msg = $Unicode::Japanese::xs_loaderror;
print "xs-load-message : [".(defined($msg)?$msg:'')."]".(!defined($msg)?' (undef)':$msg eq ''?' (empty)':'')."\n";

my $tablefh = new IO::File 'jcode/CP932.TXT'
  or die "cannot open 'jcode/CP932.TXT'";
print "reading 'jcode/CP932.TXT'...\n";

my(%s2u,%u2s);

while(<$tablefh>)
  {
    next if(m/^#/);
    next if(m/^$/);

    chomp;

    m/^0x([0-9a-fA-F]+)\s+(?:0x([0-9a-fA-F]+))?/ or die $_;
    next if(!defined($2));
    
    $s2u{hex($1)} = hex($2);
    #      CP932       Unicode
  }

%u2s = reverse(%s2u);

$| = 1;

# --------------------------------------------------------------------
# 不一致時に出力する用
sub dumpstr($$)
{
  my($hdr,$str)=@_;
  my $line = $hdr.sprintf(" : [len:%d]",length($str));
  for( my $i=0; $i<length($str); ++$i )
  {
    $line .= sprintf(" %02x",unpack('C',substr($str,$i,1)));
  }
  print STDERR $line." : $str\r\n";
}

# --------------------------------------------------------------------
# tests sjis to ucs2

print "Testing sjis=>ucs2...\n";
test_sjis_ucs2();

sub upack
{
  pack('n',shift);
}
sub sjis_ucs2
{
  my $code = shift;
  my $str = $code<=0xFF?pack("C",$code):pack('n',$code);
  exists($s2u{$code}) ? upack($s2u{$code}) :
  $code<=0xFF ? "\0?" :
  $str =~ /^[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]$/ ? "\0?" :
  (
  (exists($s2u{$code>>8}) ? upack($s2u{$code>>8}) : "\0?").
  (exists($s2u{$code&255}) ? upack($s2u{$code&255}) : "\0?")
  )
}
sub test_sjis_ucs2
{
  printf "[0x%#04x]",0;
  for( my $i=0x0; $i<=0xffff; ++$i )
  {
    if( ($i&0xFF)==0 && $i)
    {
      if( ($i&0x3FFF)==0 )
      {
	printf "\n[%#06x]",$i;
      }else
      {
	print '.';
      }
    }
    my $src = pack($i<=0xff?'c':'n',$i);
    my $code = $i;
    my $xs   = Unicode::Japanese->new($src,'sjis')->ucs2();
    my $test = sjis_ucs2($code);
    if( $xs ne $test )
    {
      print STDERR "\n";
      print STDERR "<<sjis=>utf8>>\n";
      print STDERR "i  : $i\n";
      dumpstr('sjis',$src);
      dumpstr('xs  ',$xs);
      dumpstr('test',$test);
      exit;
    }
  }
  print "\n";
}

# --------------------------------------------------------------------
# tests ucs2 to sjis

print "Testing ucs2=>sjis...\n";
test_ucs2_sjis();

sub spack
{
  my $code = shift;
  $code <= 0xFF ? pack('C',$code) : pack('n',$code);
}
sub ucs2_sjis
{
  my $code = shift;
  exists($u2s{$code}) ? spack($u2s{$code}) :
  $code<=0x7F ? chr($code) :
  '&#'.$code.';';
}

sub test_ucs2_sjis
{
  printf "[0x%#04x]",0;
  for( my $i=0x0; $i<=0xffff; ++$i )
  {
    if( ($i&0xFF)==0 && $i)
    {
      if( ($i&0x3FFF)==0 )
      {
	printf "\n[%#06x]",$i;
      }else
      {
	print '.';
      }
    }
    my $code = $i;
    my $ucs2 = pack('n',$code);
    my $xs   = Unicode::Japanese->new($ucs2,'ucs2')->sjis();
    my $test = ucs2_sjis($code);
    if( $xs ne $test )
    {
      print STDERR "\n";
      print STDERR "<<utf8=>sjis>>\n";
      printf STDERR "i  : 0x%04x\n",$i;
      dumpstr('ucs2',$ucs2);
      dumpstr('xs  ',$xs);
      dumpstr('test',$test);
      exit;
    }
  }
  print "\n";
}

# --------------------------------------------------------------------
# done

print "done\n";

# --------------------------------------------------------------------
# PurePerl code, copy from String.pl
# 
use vars qw(@U2T);

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
