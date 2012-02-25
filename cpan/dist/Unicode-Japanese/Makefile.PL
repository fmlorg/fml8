## ----------------------------------------------------------------------------
# Makefile.PL
# -----------------------------------------------------------------------------
# Makefile.PL for Unicode-Japanese.
# -----------------------------------------------------------------------------
# $Id: Makefile.PL 41491 2008-02-15 07:21:13Z hio $
# -----------------------------------------------------------------------------
package Unicode::Japanese::MakeMaker;

use strict;
use ExtUtils::Manifest;
use ExtUtils::MakeMaker;
#use File::Spec; # not included in perl-5.004.
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my $MANIFEST_bak = $ExtUtils::Manifest::MANIFEST;

my %argv = map{ /^(\w+)=(.*)$/ } @ARGV;

my $useXS; # 0:use PurePerl, 1:use XS, undef: unspecified

unlink(qw(medaite.h mediate.c));

# --------------------------------------------------------------------
# create default parameter
my %param = (
    'NAME'		=> 'Unicode::Japanese',
    'VERSION_FROM'	=> 'lib/Unicode/Japanese.pm', # looks for $VERSION
    'ABSTRACT_FROM'     => 'lib/Unicode/Japanese.pm', #
    'AUTHOR'		=> 'SANO Taku (SAWATARI Mikage) and YAMASHINA Hio',

    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PL_FILES'          => {},
    'EXE_FILES'         => ['bin/ujconv','bin/ujguess',],

    'CONFIGURE'         => \&configure,	 
    'clean'    => { FILES => 't/pureperl.flag mediate.c mediate.h' },
    'depend'   => { libunijp => ";\$(MAKE) -C c_lib" },
  );
my %param_xs = (
    'OBJECT' => join(' ',qw( Japanese.o memmap_common.o memmap_unix.o
                             conv.o ucs2_utf8.o ucs4.o utf8.o
			     getcode.o getcode_map.o sjis.o eucjp.o jis.o
			     sjis_imode1.o sjis_imode2.o sjis_jsky1.o sjis_jsky2.o sjis_doti.o utf16.o
			     mediate.o 
			     ) ),
    'XS' => {'Japanese.xs'=>'Japanese.c',},
    'XSOPT'=>'-C++',
    'XSPROTOARG'=>'-noprototypes',

    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
  );
my @CCFLAGS;

# --------------------------------------------------------------------
# add CCFLAGS
#add_ccflags('-Wall');

# --------------------------------------------------------------------
# check if we are in the developer's environment.
if( ! -e 'devel.PL' )
{
  # for release build.
  add_ccflags('-DNDEBUG');
}else
{
  # for development build.
  print "We are going to build Unicode::Japanese in developer's environment.\n";
  if( open DEVEL_PL,'devel.PL' )
  {
    my $code = join('',<DEVEL_PL>);
    eval $code;
    if( $@ )
    {
      die "'devel.PL' failed : $@";
    }
    close DEVEL_PL;
  }
  print " >> (devel mode) CCFLAGS = '$param_xs{'CCFLAGS'}'\n";
}

# --------------------------------------------------------------------
# look for 'PurePerl' or 'NoXS' from @ARGV, and remove it if exists.
my @arg;
@ARGV = grep{ !(@arg-push(@arg,/^(PurePerl|NoXS)(=(0|1|yes|no|y|n))?$/i)) } @ARGV;
if( @arg )
{
  my $v = $arg[1] ? $arg[2] : '1';
  if( $v eq '1' || $v eq 'y' || $v eq 'yes' )
  {
    print "install with PurePerl mode\n";
    disableXS();
  }
}

# --------------------------------------------------------------------
# run MakerMaker :: WriteMakefile, hints, and configure().

print " >> invoke WriteMakefile\n";
my_metafile 'Unicode::Japanese' => {
	requires => {},
	build_requires => {
		'Test'       => 0,
		'Test::More' => 0,
	},
	license => 'Perl',
};
WriteMakefile(%param);

$ExtUtils::Manifest::MANIFEST = $MANIFEST_bak;


# --------------------------------------------------------------------
# code below here has only subroutines.

sub configure
{
  print "**** CONFIGURE ****\n";
  if( $] < 5.006 )
  {
    add_ccflags('-DUNIJP__PERL_OLDER_THAN_5_006');
  }
  if( $] < 5.005 )
  {
    add_ccflags('-DUNIJP__PERL_OLDER_THAN_5_005');
  }

  if( !defined($useXS) )
  {
    print " >> no hints ran (this platform may not be supported to run XS code [$^O])\n";
    enableXS('(no hints)',undef,undef);
  }
  
  flush_ccflags();
  if( $useXS )
  {
    # compilation check.
    use Config;
    my $cc = exists $argv{CC} ? $argv{CC} : $Config{cc};
    my $ccopts = exists $argv{CCFLAGS} ? $argv{CCFLAGS} : exists $param_xs{CCFLAGS} ? $param_xs{CCFLAGS} : ccopts();
    
    my $xstest_src = $^O eq 'MSWin32' ? 'memmap_win32.c' : 'memmap_unix.c';
    my $xstest_out = $^O eq 'MSWin32' ? 'memmap_win32.obj' : 'memmap_unix.o';
    my $cmd = "$cc $ccopts -c $xstest_src -o $xstest_out";
    print "Checking if we can actually compile a C source file... : $cmd\n";
    my $rc = 0xffff & system($cmd);
    unlink($xstest_out);
    if( $rc )
    {
      if( $rc == 0xffff )
      {
	print " >> It seems we can't compile XS module in this environment.\n";
	print " >> Reason : failed to execute the C compiler: $!\n";
	return disableXS();
      }elsif( $rc > 0x80 )
      {
        print " >> It seems we can't compile XS module in this environment.\n";
	print " >> Reason : the C compiler exited with non-zero status $rc\n";
	return disableXS();
      }elsif( $rc & 0x80 )
      {
	$rc &= ~0x80;
	print " >> Compilation failed..\n";
	print " >> Reason : the C compiler coredumped because of signal $rc\n";
	exit 1;
      }else
      {
        print " >> Compilation failed..\n";
        print " >> Reason : the C compiler got killed with signal $rc\n";
	exit 1;
      }
    }
    print " >> ok, the compilation test succeeded.\n";
    
    my %SIZES;
    print "checking for size of word...\n";
    {
      my $exe_ext = $^O eq 'MSWin32' ? '.exe' : '';
      $xstest_src = 'wordsize.c';
      ($xstest_out = $xstest_src) =~ s/\.c$/$exe_ext/;
      $cmd = "$cc $ccopts $xstest_src -o $xstest_out";
      print "compiling... : $cmd\n";
      my $rc = 0xffff & system($cmd);
      if( $rc==-1 )
      {
        print " >> compilation failed: $!\n";
        return disableXS();
      }
      if( $rc!=0 )
      {
        print " >> compilation failed. exit status: $rc\n";
        return disableXS();
      }
      if( eval{ require File::Spec; 1; } )
      {
        my $curdir = File::Spec->curdir();
        $cmd = File::Spec->catfile($curdir, $xstest_out);
      }else
      {
        $cmd = "./$xstest_out";
      }
      my @list  = `$cmd`;
      if( $? )
      {
        print " >> execution failed: $?\n";
        return disableXS();
      }
      foreach(@list)
      {
        chomp;
        /^(.*?) = (\d+)/ or next;
        $SIZES{$1} = $2;
      }
    }
    foreach(qw(short int long void*))
    {
      $SIZES{$_} ||= 0;
    }
    my $int32 = $SIZES{int}*8==32 ? 'int' : 'long';
    my $int16 = $SIZES{int}*8==16 ? 'int' : 'short';
    my $int8  = 'char';
    $param_xs{DEFINE} .= qq| -DUJ_UINT32="unsigned $int32"|;
    $param_xs{DEFINE} .= qq| -DUJ_UINT16="unsigned $int16"|;
    $param_xs{DEFINE} .= qq| -DUJ_UINT8="unsigned $int8"|;
    $param_xs{DEFINE} =~s/^ //;
  }else
  {
    print "skipping XS compilation test...\n";
  }
  
  \%param_xs;
}

sub disableXS
{
  print " >> disableXS...\n";
  $useXS = 0;  
  $ExtUtils::Manifest::MANIFEST = 'MANIFEST.noxs';
  $param{linkext} = { 'LINKTYPE'=>'' };
  %param_xs = ('linkext'=>{'LINKTYPE'=>''},
              );
  if( !-e "t/pureperl.flag" )
  {
    if( open(FILE,">t/pureperl.flag") )
    {
      close(FILE);
    }else
    {
      print "could not create file [t/pureperl.flag] : $!\n";
    }
  }
  \%param_xs;
}

sub enableXS
{
  my $type = shift;
  my $hdr  = shift || "/* nothing is needed. */\n";
  my $cpp  = shift;
  my $cpp_on = $cpp && 1;
  if( !$cpp_on )
  {
    $cpp = "/* This file will not be compiled. */\n";
  }

  if( $type eq 'MSWin32' )
  {
    $param_xs{'OBJECT'} =~ s/\bmemmap_unix.o\b/memmap_win32.o/;
    $param_xs{'PM'} and delete @{$param_xs{'PM'}}{qw(Japanese/u2s-s2u.dat Japanese/emoji.dat)};
  }

  !defined($useXS) and $useXS = 1;
  print " >> enableXS...\n";
  $useXS or print " >> XS was disabled previously... (keeping it disabled)\n";
  $hdr = "/* from hints/$type.pl */\n\n".$hdr;
  $cpp = "/* from hints/$type.pl */\n\n".$cpp;

  print " >> writing mediate.c, mediate.h\n";
  use FileHandle;
  my $fh_hdr = new FileHandle('>mediate.h');
  my $fh_cpp = new FileHandle('>mediate.c');
  if( !$fh_hdr || !$fh_cpp )
  {
    die 'cannot open mediate.h or .c for output';
  }
  
  # write out 'mediate.h'
  print $fh_hdr <<EOF;
#ifndef MEDIATE_H__
#define MEDIATE_H__

/* This file was auto-generated by Makefile.PL */

$hdr

#endif
EOF

  # write out 'mediate.c'
  print $fh_cpp <<EOF;

/* This file was auto-generated by Makefile.PL */

$cpp
EOF
  
  $fh_hdr->close();
  $fh_cpp->close();
  
  if( $useXS && -e "t/pureperl.flag" )
  {
    unlink("t/pureperl.flag") or print "could not unlink file [t/pureperl.flag] : $!\n";
  }
  
  $cpp_on or $param_xs{OBJECT} =~ s/\bmediate.o\b//;
  \%param_xs;
}

# --------------------------------------------------------------------
# misc.

sub ccopts
{
  # ExtUtils::Embed::ccopts in perl-5.004 always print the result.
  my $ccopts = `$^X -MExtUtils::Embed -e ccopts`;
  $ccopts;
}

sub add_ccflags
{
  push(@CCFLAGS,@_);
  $param_xs{'CCFLAGS'} = join(' ',($param_xs{'CCFLAGS'}||ccopts()),@_);  
  #print "new-ccflags : $param_xs{'CCFLAGS'}\n";
}

sub remove_ccflags
{
  @CCFLAGS = grep{ $_ ne $_[0] } @CCFLAGS;
}

sub flush_ccflags
{
  if( @CCFLAGS )
  {
    $param_xs{'CCFLAGS'} = join(' ',ccopts(),@CCFLAGS);
    #$param_xs{'CCFLAGS'} =~ s/ -MD / -MDd /g or die $param_xs{'CCFLAGS'};
  }else
  {
    delete $param_xs{'CCFLAGS'};
  }
}

sub include_test
{
  $^O ne 'MSWin32' and add_ccflags('-g');
  add_ccflags('-DTEST=1');
  $param_xs{'OBJECT'}  .= ' test.o';
}
