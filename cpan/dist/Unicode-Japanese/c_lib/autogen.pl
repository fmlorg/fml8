#! /usr/bin/perl -w
use strict;
use warnings;

our $GENERATER = $0;
our $SIZES;
our $FILES;
our %USIZE = (
  u2s    => 2,
  s2u    => 3,
  ei2u1  => 4,
  ei2u2  => 4,
  eu2i1  => 2,
  eu2i2  => 2,
  ej2u1  => 4,
  ej2u2  => 4,
  eu2j1  => 5,
  eu2j2  => 5,
  ed2u   => 4,
  eu2d   => 2,
  ea2u1  => 2,
  ea2u2  => 2,
  eu2a1  => 2,
  eu2a2  => 2,
  ea2u1s => 2,
  ea2u2s => 2,
  eu2a1s => 2,
  eu2a2s => 2,
);

$| = 1;
load_sizes();
gen_unijp_version_h();
gen_unijp_int_h();
if( load_files() )
{
  gen_unijp_table_h();
  gen_tables();
}

# -----------------------------------------------------------------------------
# load_sizes().
#
sub load_sizes
{
  print "check sizes.\n";
  if( !-x "wordsize" )
  {
    system("make wordsize")==0 or die "system: exit=$?";
  }
  my $ret = `./wordsize`;
  my %sizes  = ( $ret =~ /^(\w+\*?) = (\d+)$/gm );

  my @int32 = grep{ $sizes{$_}==4 } qw(int long short);
  my @int16 = grep{ $sizes{$_}==2 } qw(int long short);
  @int32 or die "no 32-bit integer";
  @int16 or die "no 16-bit integer";

  $sizes{int32} = $int32[0];
  $sizes{int16} = $int16[0];
  $sizes{int8}  = 'char';

  $SIZES = \%sizes;
}

# -----------------------------------------------------------------------------
# load_files().
#
sub load_files
{
  print "check files.\n";
  if( !-e "../jcode" )
  {
    print ".. skip.\n";
    return;
  }
  my @bins = qw(
    jcode/u2s.dat           jcode/s2u.dat
    jcode/emoji2/ei2u.dat   jcode/emoji2/eu2i.dat
    jcode/emoji2/ei2u2.dat  jcode/emoji2/eu2i2.dat
    jcode/emoji2/ej2u.dat   jcode/emoji2/eu2j.dat
    jcode/emoji2/ej2u2.dat  jcode/emoji2/eu2j2.dat
    jcode/emoji2/ed2u.dat   jcode/emoji2/eu2d.dat
    jcode/emoji2/ea2u.dat   jcode/emoji2/eu2a.dat
    jcode/emoji2/ea2u2.dat  jcode/emoji2/eu2a2.dat
    jcode/emoji2/ea2us.dat  jcode/emoji2/eu2as.dat
    jcode/emoji2/ea2u2s.dat jcode/emoji2/eu2a2s.dat
  );
  my @files;
  foreach my $file (@bins)
  {
    print "- check $file ...";
    my $name = (reverse split(/[\/\.]/, $file))[1];
    $name =~ s/^(e[ijau]2[ijau])(s?)\z/${1}1$2/;
    print "($name)\n";
    my $path = "../$file";
    -e $path or die "no such file: $path";
    my $bytes = -s _;

    my $usize  = $USIZE{$name} or die "no usize for $name";
    my $chars  = $bytes / $usize;
    my $rest   = $bytes % $usize;
    $rest==0 or die "invalid rest $rest, size=$bytes, usize=$usize";

    my $file_info = {
      name   => $name,
      ucname => uc($name),
      file   => $file,
      path   => $path,
      size   => $bytes,
      usize  => $usize,
      chars  => $chars,
    };
    grep{$_->{name} eq $name} @files and die "name collision: $name";
    push(@files, $file_info);
  }

  $FILES = \@files;
  1;
}

# -----------------------------------------------------------------------------
# gen_unijp_version_h().
#
sub gen_unijp_version_h
{
  my ($ver_str, $ver_maj, $ver_min, $ver_dev);
  {
    my $file = "../lib/Unicode/Japanese.pm";
    open(my$fh, '<', $file) or die "open: $file: $!";
    while(<$fh>)
    {
      /^(__DATA__|__END__)$/ and last;
      /\$VERSION\s*=\s*'?((\d+)\.(\d+)(?:_0*(\d+))?)'?/ or next;
      $ver_str = $1;
      $ver_maj = $2;
      $ver_min = $3;
      $ver_dev = $4 || 0;
    }
    close $fh;
  }

  my $tmpl = _unijp_version_h_tmpl();
  $tmpl =~ s/<&GENERATER>/$GENERATER/g;
  $tmpl =~ s/<&VERSION>/$ver_str/g;
  $tmpl =~ s/<&VERSION_MAJOR>/$ver_maj/g;
  $tmpl =~ s/<&VERSION_MINOR>/$ver_min/g;
  $tmpl =~ s/<&VERSION_PATCH>/$ver_dev/g;

  my $outpath = "unijp_version.h";
  open(my $out, ">", $outpath) or die "open: $outpath: $!";
  print $out $tmpl;
  close $out;
}

# -----------------------------------------------------------------------------
# gen_unijp_int_h().
#
sub gen_unijp_int_h
{
  my $tmpl = _unijp_int_h_tmpl();
  $tmpl =~ s/<&GENERATER>/$GENERATER/g;

  my $outpath = "unijp_int.h";
  open(my $out, ">", $outpath) or die "open: $outpath: $!";
  my $int32 = sprintf('%-5s', $SIZES->{int32});
  my $int16 = sprintf('%-5s', $SIZES->{int16});
  my $int8  = sprintf('%-5s', $SIZES->{int8});
  $tmpl =~ s/<&INT32>/$int32/g;
  $tmpl  =~ s/<&INT16>/$int16/g;
  $tmpl  =~ s/<&INT8>/$int8/g;
  print $out $tmpl;
  close $out;
}

# -----------------------------------------------------------------------------
# gen_unijp_table_h().
#
sub gen_unijp_table_h
{
  my $tmpl = _unijp_table_h_tmpl();
  $tmpl =~ s/<&GENERATER>/$0/g;
  my ($tmpl_head, $tmpl_tail) = split(/<&DECLS>\n/, $tmpl, 2);


  my $outpath = "unijp_table.h";
  open(my $out, ">", $outpath) or die "open: $outpath: $!";
  my $int32 = sprintf('%-5s', $SIZES->{int32});
  my $int16 = sprintf('%-5s', $SIZES->{int16});
  my $int8  = sprintf('%-5s', $SIZES->{int8});
  $tmpl_head =~ s/<&INT32>/$int32/g;
  $tmpl_head =~ s/<&INT16>/$int16/g;
  $tmpl_head =~ s/<&INT8>/$int8/g;
  print $out $tmpl_head;

  print $out "/* sizes. */\n";
  foreach my $file_info (@$FILES)
  {
    my $name   = $file_info->{name};
    my $ucname = $file_info->{ucname};
    my $bytes  = $file_info->{size};
    my $usize  = $USIZE{$name} or die "no usize for $name";
    my $chars  = $bytes / $usize;
    my $rest   = $bytes % $usize;
    $rest==0 or die "invalid rest $rest, size=$bytes, usize=$usize";

    my $size_var  = "UJ_${ucname}_BYTES";
    my $chars_var = "UJ_${ucname}_CHARS";
    my $usize_var = "UJ_${ucname}_USIZE";
    my $data_var  = "_uj_${name}_table";
    print $out sprintf("#define %-18s %5d\n", $size_var,  $bytes);
    print $out sprintf("#define %-18s %5d\n", $chars_var, $chars);
    print $out sprintf("#define %-18s %5d\n", $usize_var, $usize);
  }
  print $out "\n";

  print $out "/* data. */\n";
  foreach my $file_info (@$FILES)
  {
    my $name   = $file_info->{name};
    my $ucname = $file_info->{ucname};

    my $size_var  = "UJ_${ucname}_BYTES";
    my $chars_var = "UJ_${ucname}_CHARS";
    my $usize_var = "UJ_${ucname}_USIZE";
    my $data_var  = "_uj_table_${name}";
    print $out sprintf("extern const uj_uint8 %-16s [%-15s][%-15s];\n", $data_var, $chars_var, $usize_var);
  }
  print $out "\n";

  print $out $tmpl_tail;
  close $out;
}

# -----------------------------------------------------------------------------
# gen_tables().
#
sub gen_tables
{
  print "tables ...\n";

  foreach my $file_info (@$FILES)
  {
    my $outpath = "table_$file_info->{name}.c";
    print "- $outpath ...";
    my $mtime_src = -s $file_info->{path};
    my $mtime_dst = -s $outpath;
    if( $mtime_dst && $mtime_dst > $mtime_src )
    {
      print " skip.\n";
      next;
    }
    open(my $in, '<', $file_info->{path}) or die "open: $file_info->{path}: $!";
    binmode($in);

    my $name   = $file_info->{name};
    my $ucname = uc($name);
    open(my $out, '>', $outpath) or die "open: $outpath: $!";
    print $out "/* This file is autogenerated by $GENERATER. */\n";
    print $out qq/#include "unijp_table.h"\n/;
    my $varname = "_uj_table_${name}";
    my $usize   = $USIZE{$name} or die "no unit size for $name";
    print $out "/*\n".Dumper($file_info)."*/\n";use Data::Dumper;
    print $out "const uj_uint8 $varname\[UJ_${ucname}_CHARS][UJ_${ucname}_USIZE] = {\n";
    foreach my $i (0..$file_info->{size}-1)
    {
      my $r = read($in, my $bin, 1);
      defined($r) or die "read: $!";
      $r or die "eof";
      $i%16==0 and print $out "  ";
      $i%$usize==0 and print $out "{ ";
      print $out unpack("C*", $bin);
      $i%$usize==$usize-1 and print $out " }";
      if( $i < $file_info->{size} - 1 )
      {
        print $out ",";
        print $out $i%16==15 ? "\n" : " ";
      }else
      {
        print $out "\n";
      }
    }
    print $out "};\n";

    close $in;
    close $out;
    print " ok.\n";
  }
}

sub _unijp_version_h_tmpl
{
  scalar(<<'UNIJP_VERSION_H_TMPL');
/* ----------------------------------------------------------------------------
 * unijp_version.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * This file is autogenerated by <&GENERATER>.
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_VERSION_H
#define UNIJP_VERSION_H

#ifdef __cplusplus
extern "C"
{
#endif

#define UNIJP_VERSION_STRING "<&VERSION>"
#define UNIJP_VERSION_MAJOR  <&VERSION_MAJOR>
#define UNIJP_VERSION_MINOR  <&VERSION_MINOR>
#define UNIJP_VERSION_PATCH  <&VERSION_PATCH>

#ifdef __cplusplus
}
#endif

#endif /* !defined(UNIJP_VERSION_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
UNIJP_VERSION_H_TMPL
}

sub _unijp_int_h_tmpl
{
  scalar(<<'UNIJP_INT_H_TMPL');
/* ----------------------------------------------------------------------------
 * unijp_int.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * This file is autogenerated by <&GENERATER>.
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_INT_H
#define UNIJP_INT_H

#ifdef __cplusplus
extern "C"
{
#endif

typedef unsigned <&INT32> uj_uint32;
typedef unsigned <&INT16> uj_uint16;
typedef unsigned <&INT8> uj_uint8;

#ifdef __cplusplus
}
#endif

#endif /* !defined(UNIJP_INT_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
UNIJP_INT_H_TMPL
}

sub _unijp_table_h_tmpl
{
  scalar(<<'UNIJP_TABLE_H_TMPL');
/* ----------------------------------------------------------------------------
 * unijp_table.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * This file is autogenerated by <&GENERATER>.
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_TABLE_H
#define UNIJP_TABLE_H

#ifdef __cplusplus
extern "C"
{
#endif

#include "unijp_types.h"

<&DECLS>

#ifdef __cplusplus
}
#endif

#endif /* !defined(UNIJP_TABLE_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
UNIJP_TABLE_H_TMPL
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
