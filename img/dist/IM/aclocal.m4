dnl
dnl			      aclocal.m4
dnl
dnl Author:  Internet Message Group <img@mew.org>
dnl Created: Apr 23, 1997
dnl Revised: Aug 28, 1998
dnl 

dnl IM_PATH_PERLV_PROG(VARIABLE, PROG-TO-CHECK-FOR [, VALUE-IF-NOT-FOUND
dnl                    [, PATH]])
AC_DEFUN(IM_PATH_PERLV_PROG,
[# Extract the first word of "$2", so it can be a program name with args.
set dummy $2; ac_word=[$]2
AC_MSG_CHECKING([for $ac_word])
AC_CACHE_VAL(im_cv_path_$1,
[case "[$]$1" in
  /*)
  im_cv_path_$1="[$]$1" # Let the user override the test with a path.
  ;;
  *)
  IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS="${IFS}:"
  for ac_dir in ifelse([$4], , $PATH, [$4$ac_dummy]); do
    test -z "$ac_dir" && ac_dir=.
    if test -x $ac_dir/$ac_word; then
       if $ac_dir/$ac_word -e 'require 5.003;' > /dev/null 2>&1; then
         im_cv_path_$1="$ac_dir/$ac_word"
         break
       fi
    fi
  done
  IFS="$ac_save_ifs"
ifelse([$3], , , [  test -z "[$]im_cv_path_$1" && im_cv_path_$1="$3"
])dnl
  ;;
esac])dnl
$1="$im_cv_path_$1"
if test -n "[$]$1"; then
  AC_MSG_RESULT([$]$1)
else
  AC_MSG_RESULT(no)
fi
AC_SUBST($1)dnl
])


dnl IM_PATH_PERLV_PROGS(VARIABLE, PROGS-TO-CHECK-FOR [, VALUE-IF-NOT-FOUND
dnl                     [, PATH]])
AC_DEFUN(IM_PATH_PERLV_PROGS,
[for ac_prog in $2
do
IM_PATH_PERLV_PROG($1, [$]ac_prog, , $4)
test -n "[$]$1" && break
$1=""
done
ifelse([$3], , , [test -n "[$]$1" || $1="$3"
])])


dnl IM_PATH_SITEPERL(VARIABLE, PERLV [, VALUE-IF-NOT-FOUND])
AC_DEFUN(IM_PATH_SITEPERL,
[AC_MSG_CHECKING([for site_perl])
AC_CACHE_VAL(im_cv_path_$1,
[case "[$]$1" in
  /*)
  im_cv_path_$1="[$]$1" # Let the user override the test with a path.
  ;;
  *)
  im_cv_path_$1=`$2 -MConfig -e 'print $Config{installsitelib}'`
dnl If no 3rd arg is given, leave the cache variable unset,
dnl so IM_PATH_SITEPERL will keep looking.
ifelse([$3], , , [  test -z "[$]im_cv_path_$1" && im_cv_path_$1="$3"
])dnl
  ;;
esac])dnl
$1="$im_cv_path_$1"
if test -n "[$]$1"; then
  AC_MSG_RESULT([$]$1)
else
  AC_MSG_RESULT(no)
fi
AC_SUBST($1)dnl
])


dnl IM_DB_TYPE(VARIABLE, PERL_PROG [, VALUE-IF-NOT-FOUND])
AC_DEFUN(IM_DB_TYPE,
[AC_MSG_CHECKING([for DB type])
AC_CACHE_VAL(im_cv_perl_$1,
[if test -n "[$]$1"; then
  im_cv_perl_$1="[$]$1" # Let the user override the test with a path.
else
  im_cv_perl_$1=`$2 -e 'BEGIN { @AnyDBM_File::ISA = qw(DB_File NDBM_File SDBM_File) }; dnl
  use AnyDBM_File; $db = shift @AnyDBM_File::ISA; dnl
  $db =~ s/_File//; print "$db\n";'`
dnl If no 3rd arg is given, leave the cache variable unset,
dnl so IM_DB_TYPE will keep looking.
ifelse([$3], , , [  test -z "[$]im_cv_perl_$1" && im_cv_perl_$1="$3"
])dnl
fi])dnl
$1="$im_cv_perl_$1"
if test -n "[$]$1"; then
  AC_MSG_RESULT([$]$1)
else
  AC_MSG_RESULT(no)
fi
])

dnl Copyright (C) 1997, 1998 IM developing team.
dnl All rights reserved.
dnl 
dnl Redistribution and use in source and binary forms, with or without
dnl modification, are permitted provided that the following conditions
dnl are met:
dnl 
dnl 1. Redistributions of source code must retain the above copyright
dnl    notice, this list of conditions and the following disclaimer.
dnl 2. Redistributions in binary form must reproduce the above copyright
dnl    notice, this list of conditions and the following disclaimer in the
dnl    documentation and/or other materials provided with the distribution.
dnl 3. Neither the name of the team nor the names of its contributors
dnl    may be used to endorse or promote products derived from this software
dnl    without specific prior written permission.
dnl 
dnl THIS SOFTWARE IS PROVIDED BY THE TEAM AND CONTRIBUTORS ``AS IS'' AND
dnl ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
dnl IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
dnl PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE TEAM OR CONTRIBUTORS BE
dnl LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
dnl CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
dnl SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
dnl BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
dnl WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
dnl OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
dnl IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
