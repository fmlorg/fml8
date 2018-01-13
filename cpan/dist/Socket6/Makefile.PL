# Copyright (C) 2000-2016 Hajimu UMEMOTO <ume@mahoroba.org>.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the project nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# $Id: Makefile.PL 659 2016-03-17 06:20:36Z ume $

use Config;
use ExtUtils::MakeMaker;

if ($^O eq 'MSWin32') {
    configure_mswin32();
} else {
    local $ENV{TMPDIR} = $ENV{TMPDIR};
    my $path_perl = ($^X =~ m!^/!o) ? $^X : `which $^X`;
    my $cmd = "CC='$Config{cc}' CFLAGS='$Config{ccflags}'";
    if ($^O eq 'android') {
        # Work around a bug in Android's sh:
        # http://stackoverflow.com/questions/15283220/android-shell-eof
        $ENV{TMPDIR} ||= File::Spec->tmpdir();

        # /bin/sh doesn't exist on Android, point it to the right
        # location for sh
        $cmd .= " CONFIG_SHELL='$Config{sh}'";

        # Call './configure' as 'sh ./configure'
        $cmd .= " $Config{sh}";
    }
    $cmd .= " ./configure";
    $cmd .= " --with-perl=$path_perl" if ($path_perl);
    system($cmd);
}

require './config.pl';

WriteMakefile(
    NAME	 => 'Socket6',
    VERSION_FROM => 'Socket6.pm',
    XSPROTOARG	 => '-noprototypes',	# XXX remove later?
    PM		 => {'Socket6.pm' => '$(INST_LIBDIR)/Socket6.pm'},
    CONFIGURE	 => sub { { CC => "${cc}" } },
    LIBS	 => ["${libs}"],
    realclean	 => {FILES => 'config.cache config.h config.log config.pl config.status gailookup.pl'},
);

sub configure_mswin32
{
    open(IN, '<config.pl.in') || die "Failed to open file 'config.pl.in' [$!]";
    open(OUT, '>config.pl')   || die "Failed to open file 'config.pl' [$!]";

    while (<IN>) {
	if (/\$cc/) {
	    printf(OUT "\$cc = '%s';\n", $Config::Config{cc});
	} elsif (/\$libs/) {
	    printf(OUT "\$libs = 'ws2_32.lib';\n");
	} else {
	    print OUT;
	}
    }

    close(OUT) || die "Failed to close file 'config.pl' [$!]";
    close(IN)  || die "Failed to close file 'config.pl.in' [$!]";

    open(IN, '<config.h.in') || die "Failed to open file 'config.h.in' [$!]";
    open(OUT, '>config.h')   || die "Failed to open file 'config.h' [$!]";

    print(OUT "#ifndef NTDDI_LONGHORN\n");
    print(OUT "#  define NTDDI_LONGHORN 0x06000000\n");
    print(OUT "#endif\n");

    while (<IN>) {
	if (/HAVE_PL_SV_UNDEF/) {
	    print(OUT "#define HAVE_PL_SV_UNDEF 1\n");
	} elsif (/HAVE_GETADDRINFO/) {
	    print(OUT "#define HAVE_GETADDRINFO 1\n");
	} elsif (/HAVE_GETNAMEINFO/) {
	    print(OUT "#define HAVE_GETNAMEINFO 1\n");
	} elsif (/HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID/) {
	    print(OUT "#define HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID 1\n");
        } elsif (/HAVE_INET_(PTON|NTOP)/) {
	    print(OUT "#if (NTDDI_VERSION >= NTDDI_LONGHORN)\n");
	    print(OUT "  #define HAVE_INET_$1 1\n");
	    print(OUT "#else\n");
	    print(OUT "  #undef HAVE_INET_$1\n");
	    print(OUT "#endif\n");
	} elsif (/HAVE_SOCKLEN_T/) {
	    print(OUT "#define HAVE_SOCKLEN_T 1\n");
	} else {
	    print OUT;
	}
    }

    close(OUT) || die "Failed to close file 'config.h' [$!]";
    close(IN)  || die "Failed to close file 'config.h.in' [$!]";
}
