#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

#define PERL_XS 1
#include "uni.c"

MODULE = Jcode::Unicode	PACKAGE = Jcode::Unicode

PROTOTYPES: ENABLE

char *
euc_ucs2(src)
        SV *            src
    PROTOTYPE: $;$
    CODE:
        STRLEN srclen;
        STRLEN dstlen;
        char *s = SvROK(src) ? SvPV(SvRV(src), srclen) :SvPV(src, srclen);
        dstlen = srclen * 3 + 10; /* large enough? */
	ST(0) = sv_2mortal(newSV(dstlen));
	dstlen = _euc_ucs2((unsigned char *)SvPVX(ST(0)), (unsigned char *)s);
        SvCUR_set(ST(0), dstlen);
        SvPOK_only(ST(0));
	if (SvROK(src)) { sv_setsv(SvRV(src), ST(0)); }

char *
ucs2_euc(src)
        SV *            src
    PROTOTYPE: $;$
    CODE:
        STRLEN srclen;
        STRLEN dstlen;
        char *s = SvROK(src) ? SvPV(SvRV(src), srclen) :SvPV(src, srclen);
        dstlen = srclen * 3 + 10; /* large enough? */
        ST(0) = sv_2mortal(newSV(dstlen));
        dstlen = _ucs2_euc((unsigned char *)SvPVX(ST(0)), (unsigned char *)s, srclen);
        SvCUR_set(ST(0), dstlen);
        SvPOK_only(ST(0));
	if (SvROK(src)) { sv_setsv(SvRV(src), ST(0)); }

char *
utf8_ucs2(src)
        SV *            src
    PROTOTYPE: $
    CODE:
        STRLEN srclen;
        STRLEN dstlen;
        char *s = SvROK(src) ? SvPV(SvRV(src), srclen) :SvPV(src, srclen);
        dstlen = srclen * 3 + 10; /* large enough? */
        ST(0) = sv_2mortal(newSV(dstlen));
        dstlen = _utf8_ucs2((unsigned char *)SvPVX(ST(0)), (unsigned char *)s);
        SvCUR_set(ST(0), dstlen);
        SvPOK_only(ST(0));
	if (SvROK(src)) { sv_setsv(SvRV(src), ST(0)); }

char *
ucs2_utf8(src)
        SV *            src
    PROTOTYPE: $
    CODE:
        STRLEN srclen;
        STRLEN dstlen;
        char *s = SvROK(src) ? SvPV(SvRV(src), srclen) :SvPV(src, srclen);
        dstlen = srclen * 3 + 10; /* large enough? */
        ST(0) = sv_2mortal(newSV(dstlen));
        dstlen = _ucs2_utf8((unsigned char *)SvPVX(ST(0)), (unsigned char *)s, srclen);
        SvCUR_set(ST(0), dstlen);
        SvPOK_only(ST(0));
	if (SvROK(src)) { sv_setsv(SvRV(src), ST(0)); }

char *
utf8_euc(src)
        SV *            src
    PROTOTYPE: $
    CODE:
        STRLEN srclen;
        STRLEN dstlen;
        char *s = SvROK(src) ? SvPV(SvRV(src), srclen) :SvPV(src, srclen);
        dstlen = srclen * 3 + 10; /* large enough? */
        ST(0) = sv_2mortal(newSV(dstlen));
        dstlen = _utf8_euc((unsigned char *)SvPVX(ST(0)), (unsigned char *)s);
        SvCUR_set(ST(0), dstlen);
        SvPOK_only(ST(0));
	if (SvROK(src)) { sv_setsv(SvRV(src), ST(0)); }

char *
euc_utf8(src)
        SV *            src
    PROTOTYPE: $
    CODE:
        STRLEN srclen;
        STRLEN dstlen;
        char *s = SvROK(src) ? SvPV(SvRV(src), srclen) :SvPV(src, srclen);
        dstlen = srclen * 3 + 10; /* large enough? */
        ST(0) = sv_2mortal(newSV(dstlen));
        dstlen = _euc_utf8((unsigned char *)SvPVX(ST(0)), (unsigned char *)s);
        SvCUR_set(ST(0), dstlen);
        SvPOK_only(ST(0));
	if (SvROK(src)) { sv_setsv(SvRV(src), ST(0)); }




