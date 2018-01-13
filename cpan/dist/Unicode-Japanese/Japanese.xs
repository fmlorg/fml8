
/* $Id: Japanese.xs 41491 2008-02-15 07:21:13Z hio $ */

#include "Japanese.h"

EXTERN_C SV* test(SV* str);


MODULE = Unicode::Japanese		PACKAGE = Unicode::Japanese
PROTOTYPES: DISABLE

int
__SvOK(sv)
    SV* sv;
CODE:
    RETVAL = SvOK(sv);
OUTPUT:
    RETVAL

#========================#
# SJIS <=> utf8          #
#========================#

SV*
_s2u(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_utf8(str);
OUTPUT:
    RETVAL

SV*
_u2s(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_sjis(str);
OUTPUT:
    RETVAL

#========================#
# getcode                #
#========================#

SV*
getcode(this_,str)
    SV* str;
CODE:
    RETVAL = xs_getcode(str);
OUTPUT:
    RETVAL

#========================#
# getcode_list           #
#========================#

void
getcode_list(this_,str)
    SV* str;
CODE:
    XSRETURN(xs_getcode_list(str));

#=======================#
# utf-8 validation      #
#=======================#

SV*
_validate_utf8(this_,str)
    SV* str;
CODE:
    RETVAL = xs_validate_utf8(str);
OUTPUT:
    RETVAL

#========================#
# SJIS <=> EUCJP         #
#========================#

SV*
_s2e(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_eucjp(str);
OUTPUT:
    RETVAL

SV*
_e2s(this_,str)
    SV* str;
CODE:
    RETVAL = xs_eucjp_sjis(str);
OUTPUT:
    RETVAL

#========================#
# SJIS <=> JIS           #
#========================#

SV*
_s2j(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_jis(str);
OUTPUT:
    RETVAL

SV*
_j2s(this_,str)
    SV* str;
CODE:
    RETVAL = xs_jis_sjis(str);
OUTPUT:
    RETVAL


#========================#
# SJIS(i-mode) <=> UTF8  #
#========================#

SV*
_si2u1(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_imode1_utf8(str);
OUTPUT:
    RETVAL

SV*
_si2u2(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_imode2_utf8(str);
OUTPUT:
    RETVAL

SV*
_u2si1(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_sjis_imode1(str);
OUTPUT:
    RETVAL

SV*
_u2si2(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_sjis_imode2(str);
OUTPUT:
    RETVAL

#========================#
# SJIS(j-sky) <=> UTF8   #
#========================#

SV*
_sj2u1(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_jsky1_utf8(str);
OUTPUT:
    RETVAL

SV*
_sj2u2(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_jsky2_utf8(str);
OUTPUT:
    RETVAL

SV*
_u2sj1(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_sjis_jsky1(str);
OUTPUT:
    RETVAL

SV*
_u2sj2(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_sjis_jsky2(str);
OUTPUT:
    RETVAL

#========================#
# SJIS(dot-i) <=> UTF8   #
#========================#

SV*
_sd2u(this_,str)
    SV* str;
CODE:
    RETVAL = xs_sjis_doti_utf8(str);
OUTPUT:
    RETVAL

SV*
_u2sd(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_sjis_doti(str);
OUTPUT:
    RETVAL

#========================#
# ucs2 <=> utf8          #
#========================#

SV*
_ucs2_utf8(this_,str)
    SV* str;
CODE:
    RETVAL = xs_ucs2_utf8(str);
OUTPUT:
    RETVAL

SV*
_utf8_ucs2(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_ucs2(str);
OUTPUT:
    RETVAL

#========================#
# ucs4 <=> utf8          #
#========================#

SV*
_ucs4_utf8(this_,str)
    SV* str;
CODE:
    RETVAL = xs_ucs4_utf8(str);
OUTPUT:
    RETVAL

SV*
_utf8_ucs4(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_ucs4(str);
OUTPUT:
    RETVAL

#========================#
# utf-16 <=> utf-8       #
#========================#

SV*
_utf16_utf8(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf16_utf8(str);
OUTPUT:
    RETVAL

SV*
_utf8_utf16(this_,str)
    SV* str;
CODE:
    RETVAL = xs_utf8_utf16(str);
OUTPUT:
    RETVAL

#=======================#
# memory mapped file    #
#=======================#

void
do_memmap()

void
do_memunmap()
