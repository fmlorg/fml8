
use vars qw(%param %param_xs $ostype);

init_param();
add_ccflags('-Werror');
#add_ccflags('-DNDEBUG'); # uncomment for release, 
#include_test();
do_mediate();

use ExtUtils::MakeMaker;
WriteMakefile(%param,%param_xs);

sub include_test
{
  $param_xs{'CCFLAGS'} .= '-g -DTEST=1';
  $param_xs{'OBJECT'}  .= ' test.o';
}

#
# mediate.h/mediate.cpp の作成
sub do_mediate
{
  # check @ARGV
  my @arg;
  @ARGV = grep{ !(@arg-push(@arg,/^(PurePerl|NoXS)(=(0|1|yes|no|y|n))?$/i)) } @ARGV;
  if( @arg )
  {
    my $v = $arg[1] ? $arg[2] : '1';
    if( $v eq '1' || $v eq 'y' || $v eq 'yes' )
    {
      print "install with PurePerl mode\n";
      disable_xs();
      return;
    }
  }
  $ostype = `uname -s` || '';
  if( $ostype =~ /(Linux)/ )
  {
    $ostype = $1;
  }elsif( $ostype =~ /(BSD)/ )
  {
    $ostype = $1;
    $hdr = "#include <fcntl.h>\n\n";
  }elsif( $ostype =~ /(SunOS)/ )
  {
    $ostype = $1;
    $hdr = "#include <fcntl.h>\n\n";
  }elsif( !$ostype )
  {
    print "Here environment cannot use XS.\n";
    disable_xs();
    return;
  }

  if( $] < 5.006 )
  {
    /`/;
    $hdr .= <<'EOF';
#define aTHX_
#define pTHX_
#define dTHX_

#define get_av(var_name,create_flag) perl_get_av(var_name,create_flag);

#ifndef newSVpvn
#define newSVpvn(str,len) newSVpv(str,len)
#endif

EOF
    if( $] < 5.005 )
    {
      # PL_naも作ってもいいけどむしろ使わない方向で.
      $hdr .= <<'EOF';
#ifndef PL_sv_undef
#define PL_sv_undef sv_undef
#endif
EOF
    } # if( $] < 5.005 )
  /`/;
  } # if( $] < 5.006 )

  use FileHandle;
  my $fh_hdr = new FileHandle('>mediate.h');
  my $fh_cpp = new FileHandle('>mediate.cpp');
  if( !$fh_hdr || !$fh_cpp )
  {
    die 'cannot open mediate.h or .cpp for output';
  }

  $hdr = "/* nothing is needed. */\n" unless( $hdr );
  $cpp = "/* nothing is needed. */\n" unless( $cpp );

  print $fh_cpp <<EOF;

#include "Japanese.h"

$cpp
EOF

  print $fh_hdr <<EOF;
#ifndef MEDIATE_H__
#define MEDIATE_H__

$hdr
#endif
EOF

  # compile check.
  my $cmd = "$param_xs{CC} -shared -c xs_test.c";
  print "Checking XS Compiling... : $cmd\n";
  my $rc = 0xffff & system($cmd);
  if( $rc )
  {
    if( $rc == 0xffff )
    {
      print "Here environment cannot use XS.\n";
      print "Because : command failed : $!\n";
      disable_xs();
      return;
    }elsif( $rc > 0x80 )
    {
      print "Here environment cannot use XS.\n";
      print "Because : ran with non-zero exit status $rc\n";
      disable_xs();
      return;
    }elsif( $rc & 0x80 )
    {
      $rc &= ~0x80;
      print "Compile failed..\n";
      print "Because : ran with coredump from signal $rc\n";
      exit 1;
    }else
    {
      print "Compile failed..\n";
      print "Because : ran with signal $rc\n";
      exit 1;
    }
  }
  unlink('xs_test.o');
}

sub disable_xs
{
  use ExtUtils::Manifest;
  $ExtUtils::Manifest::MANIFEST = 'MANIFEST.noxs';
  %param_xs = ('linkext'=>{'LINKTYPE'=>''});
  #rename('Japanese','Japanese-notused');
}

sub init_param
{
  my $cc = 'g++';
  my $ld = $cc;
  
  @ARGV = grep{ /^CC=(.*)/ ? !($cc=$1) : 1 } @ARGV;

  my $object = join(' ',qw( Japanese.o memmap.o conv.o ucs2_utf8.o
			    getcode.o getcode_map.o sjis.o eucjp.o jis.o
			    sjis_imode.o sjis_jsky.o sjis_doti.o
			    mediate.o 
			    ) );

  %param = (
    'NAME'		=> 'Unicode::Japanese',
    'VERSION_FROM'	=> 'Japanese.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
  );
  %param_xs = (
    'EXE_FILES' => ['Japanese/u2s-s2u.dat','Japanese/emoji.dat'],
    'INSTALLSCRIPT' => '$(INST_LIBDIR)',
    'CC' => $cc,
    'CCFLAGS' => '-Wall',
    'LD' => $ld,
    'OBJECT' => $object,
    'XS' => {'Japanese.xs','Japanese.c',},
    'XSOPT'=>'-C++',
    'XSPROTOARG'=>'-prototypes',

    'clean'    => { FILES => 'mediate.{cpp,h}' },
  );
}

sub add_ccflags
{
  $param_xs{'CCFLAGS'} = join(' ',$param_xs{'CC_FLAGS'},@_);  
}
