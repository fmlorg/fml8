#! /usr/bin/perl

use strict;
use warnings;

my $prog = $0;
$prog =~ s/\.t$// or die "invalid prog name";

my $src = "$prog.c";

$prog =~ /\// or $prog = "./$prog";

my $cc      = 'gcc';
my $cflags  = '-I. -I..';
my $ldflags = '-L. -L..';
my $ldlibs  = '-lunijp';

my $cmd = "$cc $cflags $ldflags $src $ldlibs -o $prog && $prog";
my $r = system($cmd);
if( $r!=0 )
{
  my $signo = $? & 127;
  my $xval  = $? >> 8;
  $signo and die "system: signal $signo <<$cmd>>";
  $xval  and die "system: exit $xval <<$cmd>>";
}
