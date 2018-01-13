dnl Copyright (C) 2000-2016 Hajimu UMEMOTO <ume@mahoroba.org>.
dnl All rights reserved.
dnl
dnl Redistribution and use in source and binary forms, with or without
dnl modification, are permitted provided that the following conditions
dnl are met:
dnl 1. Redistributions of source code must retain the above copyright
dnl    notice, this list of conditions and the following disclaimer.
dnl 2. Redistributions in binary form must reproduce the above copyright
dnl    notice, this list of conditions and the following disclaimer in the
dnl    documentation and/or other materials provided with the distribution.
dnl 3. Neither the name of the project nor the names of its contributors
dnl    may be used to endorse or promote products derived from this software
dnl    without specific prior written permission.
dnl
dnl THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
dnl ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
dnl IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
dnl ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
dnl FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
dnl DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
dnl OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
dnl HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
dnl LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
dnl OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
dnl SUCH DAMAGE.

dnl $Id: aclocal.m4 682 2016-07-11 05:44:06Z ume $

dnl SOCKET6_CHECK_PL_SV_UNDEF(VALUE-IF-FOUND , VALUE-IF-NOT-FOUND
dnl                           [, PERL-PATH])
AC_DEFUN([SOCKET6_CHECK_PL_SV_UNDEF], [
AC_MSG_CHECKING([whether your Perl5 have PL_sv_undef])
AC_CACHE_VAL(socket6_cv_pl_sv_undef,[
rm -rf conftest
mkdir conftest
cd conftest
cat >Makefile.PL <<EOF
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME	 => 'conftest',
    VERSION_FROM => 'conftest.pm',
    XSPROTOARG	 => '-noprototypes',
);
EOF
cat > conftest.pm <<EOF
package conftest;
use vars qw(\$VERSION);
\$VERSION = "0.0";
EOF
cat > conftest.xs <<EOF
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
MODULE = conftest	PACKAGE = conftest
void
conftest()
	CODE:
	ST(0) = &PL_sv_undef;
EOF
ifelse([$3], , socket6_cv_perl_path='perl', socket6_cv_perl_path=$3)
if { (eval $socket6_cv_perl_path Makefile.PL) 2>&5 >/dev/null; (eval make) 2>&5 >/dev/null; }; then
	socket6_cv_pl_sv_undef='yes'
else
	socket6_cv_pl_sv_undef='no'
fi
cd ..
rm -rf conftest
])
if test $socket6_cv_pl_sv_undef = 'yes'; then
	AC_MSG_RESULT(yes)
	ifelse([$1], , :, [$1])
else
	AC_MSG_RESULT(no)
	ifelse([$2], , :, [$2])
fi
])

dnl IPv6_CHECK_SIN6_SCOPE_ID(VALUE-IF-FOUND , VALUE-IF-NOT-FOUND)
AC_DEFUN([IPv6_CHECK_SIN6_SCOPE_ID], [
AC_MSG_CHECKING([whether you have sin6_scope_id in struct sockaddr_in6])
AC_CACHE_VAL(ipv6_cv_sin6_scope_id, [dnl
AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>],
	[struct sockaddr_in6 sin6; int i = sin6.sin6_scope_id;],
	[ipv6_cv_sin6_scope_id=yes], [ipv6_cv_sin6_scope_id=no])])dnl
if test $ipv6_cv_sin6_scope_id = yes; then
  ifelse([$1], , AC_DEFINE(HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID,[1],[Do we have a sin6_scope_id in struct sockaddr_in6?]), [$1])
else
  ifelse([$2], , :, [$2])
fi
AC_MSG_RESULT($ipv6_cv_sin6_scope_id)])
dnl
dnl whether you have sa_len in struct sockaddr
AC_DEFUN([IPv6_CHECK_SA_LEN], [
AC_MSG_CHECKING([whether you have sa_len in struct sockaddr])
AC_CACHE_VAL(ipv6_cv_sa_len, [dnl
AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/socket.h>],
	       [struct sockaddr sa; int i = sa.sa_len;],
	       [ipv6_cv_sa_len=yes], [ipv6_cv_sa_len=no])])dnl
if test $ipv6_cv_sa_len = yes; then
  ifelse([$1], , AC_DEFINE(HAVE_SOCKADDR_SA_LEN,[1],[Does sockaddr have an sa_len?]), [$1])
else
  ifelse([$2], , :, [$2])
fi
AC_MSG_RESULT($ipv6_cv_sa_len)])
dnl
dnl See whether we can use IPv6 related functions
AC_DEFUN([IPv6_CHECK_FUNC], [
AH_TEMPLATE(AS_TR_CPP(HAVE_$1), [Define to 1 if you have the `]$1[' function.])
AC_CHECK_FUNC($1, [dnl
  ac_cv_lib_socket_$1=no
  ac_cv_lib_inet6_$1=no
], [dnl
  AC_CHECK_LIB(socket, $1, [dnl
    LIBS="$LIBS -lsocket -lnsl"
    ac_cv_lib_inet6_$1=no
  ], [dnl
    AC_MSG_CHECKING([whether your system has IPv6 directory])
    AC_CACHE_VAL(ipv6_cv_dir, [dnl
      for ipv6_cv_dir in /usr/local/v6 /usr/inet6 no; do
	if test $ipv6_cv_dir = no -o -d $ipv6_cv_dir; then
	  break
	fi
      done])dnl
    AC_MSG_RESULT($ipv6_cv_dir)
    if test $ipv6_cv_dir = no; then
      ac_cv_lib_inet6_$1=no
    else
      if test x$ipv6_libinet6 = x; then
	ipv6_libinet6=no
	SAVELDFLAGS="$LDFLAGS"
	LDFLAGS="$LDFLAGS -L$ipv6_cv_dir/lib"
      fi
      AC_CHECK_LIB(inet6, $1, [dnl
	if test $ipv6_libinet6 = no; then
	  ipv6_libinet6=yes
	  LIBS="$LIBS -linet6"
	fi],)dnl
      if test $ipv6_libinet6 = no; then
	LDFLAGS="$SAVELDFLAGS"
      fi
    fi])dnl
])dnl
ipv6_cv_$1=no
if test $ac_cv_func_$1 = yes -o $ac_cv_lib_socket_$1 = yes \
     -o $ac_cv_lib_inet6_$1 = yes
then
  ipv6_cv_$1=yes
fi
if test $ipv6_cv_$1 = no; then
  if test $1 = getaddrinfo; then
    for ipv6_cv_pfx in o n; do
      AC_EGREP_HEADER(${ipv6_cv_pfx}$1, netdb.h,
		      [AC_CHECK_FUNC(${ipv6_cv_pfx}$1)])
      if eval test X\$ac_cv_func_${ipv6_cv_pfx}$1 = Xyes; then
	ipv6_cv_$1=yes
	break
      fi
    done
  fi
fi
if test $ipv6_cv_$1 = yes; then
  AC_DEFINE_UNQUOTED(AS_TR_CPP(HAVE_$1))
  ifelse([$2], , :, [$2])
else
  ifelse([$3], , :, [$3])
fi])
dnl
dnl See whether sys/socket.h has socklen_t
AC_DEFUN([IPv6_CHECK_SOCKLEN_T], [
AC_MSG_CHECKING(for socklen_t)
AC_CACHE_VAL(ipv6_cv_socklen_t, [dnl
AC_TRY_LINK([#include <sys/types.h>
#include <sys/socket.h>],
	    [socklen_t len = 0;],
	    [ipv6_cv_socklen_t=yes], [ipv6_cv_socklen_t=no])])dnl
if test $ipv6_cv_socklen_t = yes; then
  ifelse([$1], , AC_DEFINE(HAVE_SOCKLEN_T,[1],[Do we have a socklen_t?]), [$1])
else
  ifelse([$2], , :, [$2])
fi
AC_MSG_RESULT($ipv6_cv_socklen_t)])
dnl
dnl Check if darwin inet_ntop is broken
AC_DEFUN([IPv6_CHECK_INET_NTOP], [
AC_MSG_CHECKING(for working inet_ntop)
AC_CACHE_VAL(ipv6_cv_can_inet_ntop, [dnl
AC_RUN_IFELSE([AC_LANG_SOURCE[
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int
main() {
  static struct in6_addr addr;
  static char str[INET6_ADDRSTRLEN];

  addr.s6_addr[15] = 0x21;
  inet_ntop(AF_INET6, &addr, str, sizeof(str));
  if (strcmp(str, "::21") && strcmp(str, "::0.0.0.33"))
    exit(1);
}
]], [ipv6_cv_can_inet_ntop=yes], [ipv6_cv_can_inet_ntop=no])])dnl
dnl
if test $ipv6_cv_can_inet_ntop = yes; then
  ifelse([$1], , AC_DEFINE(CAN_INET_NTOP,[1],[Do we have a working inet_ntop?]), [$1])
else
  ifelse([$2], , :, [$2])
fi
AC_MSG_RESULT($ipv6_cv_can_inet_ntop)])
