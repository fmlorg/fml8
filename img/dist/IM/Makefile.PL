### This -*- perl -*- script writes the Makefile by ukai
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Feb 28, 2000
###
### perl Makefile.PL
### make
### make install or make install_rpop
###

require 5.004;
use Config;

BEGIN {
    $VERSION = '100';
    $im_db_type = "DB";

    # this should be in BEGIN section.
    if ($im_db_type) {
	@AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File SDBM_File ODBM_File);
	unshift(@AnyDBM_File::ISA, "${im_db_type}_File");
	print "try DB type: @AnyDBM_File::ISA\n";
    } else {
	print "ignore DB type\n";
    }
}

if (open(CONFIN, "configure.in")) {
    while (<CONFIN>) {
	/^im_/ && eval "\$$_";
    }
    close(CONFIN);
}

if ($Config{'osname'} ne 'MSWin32'){
$prefix = "/usr/local";
$libdir = "\$exec_prefix/lib";
} else {
  $prefix = $Config{'prefix'};
  $prefix =~ s:\\:/:g;
  $libdir = $Config{'sitelib'};
  $libdir =~ s:\\:/:g;
}
chomp($im_hostname);
if ($Config{osname} eq "solaris") {
    $im_usecl='yes';
} else {
    $im_usecl='no';
}
$im_nosync='no';

# checking DB type
if ($im_db_type) {
    use AnyDBM_File;
    $im_db_type="$AnyDBM_File::ISA[0]";
    $im_db_type =~ s/_File$//;
    print "Your DB type is $im_db_type\n";
}

# generate im*.in -> im*.PL
opendir(DIR, ".") or die "cannot opendir .: $!";
@programs_to_install = @pl_files = ();
foreach (grep(/\.in$/ && !/^(configure|Makefile|IM)/, readdir DIR)) {
    open(IN, "$_") or die "cannot open $_.in: $!";
    s/.in$//;
    push(@programs_to_install, "$_");
    open(PL, ">$_.PL") or die "cannot open $_.PL: $!";
    push(@pl_files, "$_.PL");
    print PL <<"!SUBST!";
use Config;
(\$file = \$0) =~ s/\\.PL\$//i;
open(OUT, ">\$file") or die "Cannot create \$file: $!";
chmod(0755, \$file);
print "Extracting \$file (with variable substitutions)\n";
print OUT << \"!GROK!THIS\";
\$Config{'startperl'}

!GROK!THIS
while (<DATA>) {
    /^#! \\\@im_path_perl\\\@/ && next;
    s/\\\@im_my_siteperl\\\@//;
    s/\\\@im_src_siteperl\\\@//;
    print OUT;
}
close(OUT);
exit 0;
__END__
!SUBST!
    while (<IN>) {
	print PL $_;
    }
    close(IN);
    close(PL);
}
closedir(DIR);

# generate IM/Config.pm.in -> IM/Config.pm
#          cnf.im/SiteConfig.in -> cnf.im/SiteConfig
@generate_files = ('IM/Config.pm', 'cnf.im/SiteConfig');
foreach (@generate_files) {
    open(IN, "$_.in") or die "cannot open $_.in: $!";
    open(PM, ">$_") or die "cannot open $_: $!";
    print "Extracting $_ (with variable substitutions)\n";
    while (<IN>) {
	s/\@prefix\@/$prefix/;	# Config.pm.in
	s/\@exec_prefix\@/$prefix/;
	s/\@libdir\@/$libdir/;
	s/\@im_db_type\@/$im_db_type/;
	s/\@im_file_attr\@/$im_file_attr/;
	s/\@im_hostname\@/$im_hostname/;
	s/\@im_usecl\@/$im_usecl/;
	s/\@im_nosync\@/$im_nosync/;
	print PM;
    }
    close(IN);
    close(PM);
}
closedir(DIR);

# write Makefile
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'IM',
    'VERSION' => $VERSION,
    'EXE_FILES' => \@programs_to_install,
    'MAN1PODS' => {},
    'MAN3PODS' => {},
    'PREFIX' => $prefix,
    'clean' => { FILES => join(' ', '$(EXE_FILES)', 
			       @pl_files, @generate_files) },
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
); 

# special rules
sub MY::postamble {
    my ($self) = shift;
    my (@m);
    if ($Config{'osname'} ne 'MSWin32'){
    push (@m, qq{
prefix=$prefix
exec_prefix=$prefix
libdir=\$(exec_prefix)/lib
IM_SITECONFIG_DIR=\$(libdir)/im

install:: install_config

install_config: cnf.im/SiteConfig
	\$(MKPATH) \$(IM_SITECONFIG_DIR)
	for cnf_im in SiteConfig ; do \\
	    if \$(TEST_F) \$(IM_SITECONFIG_DIR)/\$\$cnf_im; then \\
		(\$(CP) cnf.im/\$\$cnf_im \$(IM_SITECONFIG_DIR)/\$\$cnf_im.new;) \\
	    else \\
		(\$(CP) cnf.im/\$\$cnf_im \$(IM_SITECONFIG_DIR);) \\
	    fi \\
	done
	\$(CHMOD) -R 0644 \$(IM_SITECONFIG_DIR)/*
	\$(CHMOD) 755 \$(IM_SITECONFIG_DIR)

uninstall:: uninstall_config

uninstall_config::
	\$(RM_F) \$(IM_SITECONFIG_DIR)/SiteConfig

install_rpop: install
	\$(PERL) -e 'chown(0, (getgrnam("mail"))[2], \@ARGV) and chmod(04555, \@ARGV);' \$(INSTALLSCRIPT)/imget
    });
  } else {
    push (@m, qq{
install:: install_progs

install_progs:
    \$(CP) Win32\*.exe \$(INSTALLBIN)
  });
    join "", @m;
  }
}

### Copyright (C) 1997, 1998, 1999 IM developing team
### All rights reserved.
### 
### Redistribution and use in source and binary forms, with or without
### modification, are permitted provided that the following conditions
### are met:
### 
### 1. Redistributions of source code must retain the above copyright
###    notice, this list of conditions and the following disclaimer.
### 2. Redistributions in binary form must reproduce the above copyright
###    notice, this list of conditions and the following disclaimer in the
###    documentation and/or other materials provided with the distribution.
### 3. Neither the name of the team nor the names of its contributors
###    may be used to endorse or promote products derived from this software
###    without specific prior written permission.
### 
### THIS SOFTWARE IS PROVIDED BY THE TEAM AND CONTRIBUTORS ``AS IS'' AND
### ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
### IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
### PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE TEAM OR CONTRIBUTORS BE
### LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
### CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
### SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
### BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
### WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
### OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
### IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
