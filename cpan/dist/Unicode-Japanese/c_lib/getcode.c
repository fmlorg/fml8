/* ----------------------------------------------------------------------------
 * getcode.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "unijp.h"
#include "unijp_build.h"

#include "xs_compat.h"
#define map_ascii       _uj_xs_map_ascii
#define map_eucjp       _uj_xs_map_eucjp
#define map_sjis        _uj_xs_map_sjis
#define map_utf8        _uj_xs_map_utf8
#define map_jis         _uj_xs_map_jis
#define map_jis_au      _uj_xs_map_jis_au
#define map_jis_jsky    _uj_xs_map_jis_jsky
#define map_utf32_be    _uj_xs_map_utf32_be
#define map_utf32_le    _uj_xs_map_utf32_le
#define map_sjis_jsky   _uj_xs_map_sjis_jsky
#define map_sjis_imode  _uj_xs_map_sjis_imode
#define map_sjis_doti   _uj_xs_map_sjis_doti
#define map_sjis_au     _uj_xs_map_sjis_au

#define _is_acceptable_state _uj_xs__is_acceptable_state
#define cc_tmpl _uj_xs_cc_tmpl
#define getcode_list _uj_xs_getcode_list

#define NO_XSUBS
#include "../getcode.c"

/* ----------------------------------------------------------------------------
: uj_getcode(str, len).
+--------------------------------------------------------------------------- */
uj_charcode_t uj_getcode(const uj_uint8* str, uj_size_t len)
{
  uj_conv_t conv;
  int matches;
  CodeCheck check[cc_tmpl_max];
  
  _uj_conv_set_const(&conv, _uj_default_alloc, str, len);
  matches = getcode_list(&conv, check);
  if( matches>0 )
  {
    int index = 0;
#if TEST && GC_DISP
    fprintf(stderr,"<selected>\n");
    fprintf(stderr,"  %d of 0..%d\n",index,matches-1);
    fprintf(stderr,"  %s\n",charcodeToStr(check[index].code));
#endif
    switch(check[index].code)
    {
    case cc_unknown:    return ujc_undefined;
    case cc_ascii:      return ujc_ascii;
    case cc_sjis:       return ujc_sjis;
    case cc_eucjp:      return ujc_eucjp;
    case cc_jis:        return ujc_jis;
    // case cc_jis_au:     return ujc_jis_au;
    // case cc_jis_jsky:   return ujc_jis_jsky;
    case cc_utf8:       return ujc_utf8;
    // case cc_utf16:      return ujc_utf16;
    // case cc_utf32:      return ujc_utf32;
    // case cc_utf32_be:   return ujc_utf32_be;
    // case cc_utf32_le:   return ujc_utf32_le;
    // case cc_sjis_jsky:  return ujc_sjis_jsky;
    // case cc_sjis_imode: return ujc_sjis_imode;
    // case cc_sjis_doti:  return ujc_sjis_doti;
    // case cc_sjis_au:    return ujc_sjis_au;
    default: return ujc_undefined;
    }
  }else
  {
    return ujc_undefined;
  }
}

#if 0
/* getcode_list関数 */
int xs_getcode_list(SV* sv_str)
{
  int matches;
  CodeCheck check[cc_tmpl_max];
  int i;
  dSP; dMARK; dAX; /* XSARGS; - items */
  
  if( sv_str==&PL_sv_undef )
  {
    return 0;
  }
  matches = getcode_list(sv_str, check);
  if( matches<=0 )
  {
    return 0;
  }
  EXTEND(SP, matches);
  for( i=0; i<matches; ++i )
  {
    switch(check[i].code)
    {
    case cc_unknown:    ST(i) = sv_2mortal( new_CC_UNKNOWN()    ); break;
    case cc_ascii:      ST(i) = sv_2mortal( new_CC_ASCII()      ); break;
    case cc_sjis:       ST(i) = sv_2mortal( new_CC_SJIS()       ); break;
    case cc_eucjp:      ST(i) = sv_2mortal( new_CC_EUCJP()      ); break;
    case cc_jis:        ST(i) = sv_2mortal( new_CC_JIS()        ); break;
    case cc_jis_au:     ST(i) = sv_2mortal( new_CC_JIS_AU()     ); break;
    case cc_jis_jsky:   ST(i) = sv_2mortal( new_CC_JIS_JSKY()   ); break;
    case cc_utf8:       ST(i) = sv_2mortal( new_CC_UTF8()       ); break;
    case cc_utf16:      ST(i) = sv_2mortal( new_CC_UTF16()      ); break;
    case cc_utf32:      ST(i) = sv_2mortal( new_CC_UTF32()      ); break;
    case cc_utf32_be:   ST(i) = sv_2mortal( new_CC_UTF32_BE()   ); break;
    case cc_utf32_le:   ST(i) = sv_2mortal( new_CC_UTF32_LE()   ); break;
    case cc_sjis_jsky:  ST(i) = sv_2mortal( new_CC_SJIS_JSKY()  ); break;
    case cc_sjis_imode: ST(i) = sv_2mortal( new_CC_SJIS_IMODE() ); break;
    case cc_sjis_doti:  ST(i) = sv_2mortal( new_CC_SJIS_DOTI()  ); break;
    default:            ST(i) = sv_2mortal( new_CC_UNKNOWN()    ); break;
    }
  }
  return matches;
}
#endif

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
