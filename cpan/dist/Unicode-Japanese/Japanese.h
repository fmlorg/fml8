
#ifndef UNICODE__JAPANESE_H__
#define UNICODE__JAPANESE_H__

/* $Id: Japanese.h 41491 2008-02-15 07:21:13Z hio $ */

#if !defined(__cplusplus) && !defined(bool)
#define bool char
#define true 1
#define false 0
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mediate.h"

#ifndef assert
#include <assert.h>
#endif

#include "str.h"

#ifdef TEST
/* ``TEST'' is defined by devel.PL */
#include "test.h"
#define ONTEST(cmd) cmd
#else
#define ONTEST(cmd)
#endif

#ifndef EXTERN_C
#  ifdef __cplusplus
#    define EXTERN_C extern "C"
#  else
#    define EXTERN_C
#  endif
#endif

/* misc. */
#define new_SV_UNDEF() newSVsv(&PL_sv_undef)

/* -------------------------------------------------------------------
 * XS methods.
 */
#ifdef __cplusplus
extern "C"
{
#endif
  /* sjis <=> utf8  (conv.cpp) */
  SV* xs_sjis_utf8(SV* sv_str);
  SV* xs_utf8_sjis(SV* sv_str);

  /* getcode  (getcode.cpp) */
  SV* xs_getcode(SV* sv_str);
  int xs_getcode_list(SV* sv_str);

  /* utf-8 validation (utf8.c) */
  SV* xs_validate_utf8(SV* sv_str);

  /* sjis<=>eucjp, sjis<=>jis */
  SV* xs_sjis_eucjp(SV* sv_str);
  SV* xs_eucjp_sjis(SV* sv_str);
  SV* xs_sjis_jis(SV* sv_str);
  SV* xs_jis_sjis(SV* sv_str);

  /* sjis(i-mode)<=>utf8 */
  SV* xs_sjis_imode1_utf8(SV* sv_str);
  SV* xs_sjis_imode2_utf8(SV* sv_str);
  SV* xs_utf8_sjis_imode1(SV* sv_str);
  SV* xs_utf8_sjis_imode2(SV* sv_str);

  /* sjis(j-sky)<=>utf8 */
  SV* xs_sjis_jsky1_utf8(SV* sv_str);
  SV* xs_sjis_jsky2_utf8(SV* sv_str);
  SV* xs_utf8_sjis_jsky1(SV* sv_str);
  SV* xs_utf8_sjis_jsky2(SV* sv_str);

  /* sjis(dot-i)<=>utf8 */
  SV* xs_sjis_doti_utf8(SV* sv_str);
  SV* xs_utf8_sjis_doti(SV* sv_str);

  /* ucs2<=>utf-8 */
  SV* xs_ucs2_utf8(SV* sv_str);
  SV* xs_utf8_ucs2(SV* sv_str);
  
  /* ucs4<=>utf-8 */
  SV* xs_ucs4_utf8(SV* sv_str);
  SV* xs_utf8_ucs4(SV* sv_str);
  
  /* utf-16<=>utf8 */
  SV* xs_utf16_utf8(SV* sv_str);
  SV* xs_utf8_utf16(SV* sv_str);
  
/* init/cleanup memoey map. */
/* (ja:) メモリマップファイル関連 */
extern void do_memmap(void);
extern void do_memunmap(void);

/* SJIS <=> UTF8 mapping table      */
/* (ja:) SJIS <=> UTF8 変換テーブル */
/* index is in 0..0xffff            */
extern UJ_UINT8 const* g_u2s_table;
extern UJ_UINT8 const* g_s2u_table;

  /* i-mode/j-sky/dot-i emoji <=> UTF8 mapping table */
  /* (ja:) i-mode/j-sky/dot-i 絵文字 <=> UTF8 変換テーブル */
  extern UJ_UINT32 const* g_ei2u1_table;
  extern UJ_UINT32 const* g_ei2u2_table;
  extern UJ_UINT16 const* g_eu2i1_table;
  extern UJ_UINT16 const* g_eu2i2_table;
  extern UJ_UINT32 const* g_ej2u1_table;
  extern UJ_UINT32 const* g_ej2u2_table;
  extern UJ_UINT8  const* g_eu2j1_table; /* char [][5] */
  extern UJ_UINT8  const* g_eu2j2_table; /* char [][5] */
  extern UJ_UINT32 const* g_ed2u_table;
  extern UJ_UINT16 const* g_eu2d_table;

  /* i-mode/j-sky/dot-i絵文字 <=> UTF8 変換テーブルの要素数 */
  /* バイト数でなく要素数                                   */
  extern int g_ei2u1_size;
  extern int g_ei2u2_size;
  extern int g_eu2i1_size;
  extern int g_eu2i2_size;
  extern int g_ej2u1_size;
  extern int g_ej2u2_size;
  extern int g_eu2j1_size;
  extern int g_eu2j2_size;
  extern int g_ed2u_size;
  extern int g_eu2d_size;
#ifdef __cplusplus
}
#endif

#ifdef UNIJP__PERL_OLDER_THAN_5_006
/* above symbol is defined by Makefile.PL:sub configure. */

#define aTHX_
#define pTHX_
#define dTHX_
#define get_av(var_name,create_flag) perl_get_av(var_name,create_flag);

#ifndef newSVpvn
#define newSVpvn(str,len) newSVpv(str,len)
#endif

#endif /* UNIJP__PERL_OLDER_THAN_5_006 */

#ifdef UNIJP__PERL_OLDER_THAN_5_005
/* above symbol is defined by Makefile.PL:sub configure. */
#ifndef PL_sv_undef
#define PL_sv_undef sv_undef
#endif
#endif /* UNIJP__PERL_OLDER_THAN_5_005 */

/* for 5.005_xx */
#ifndef call_pv
#define call_pv perl_call_pv
#endif
#ifndef eval_pv
#define eval_pv perl_eval_pv
#endif
#ifndef get_sv
#define get_sv perl_get_sv
#endif

/* for 5.004_xx */
#ifndef PL_na
#define PL_na UNIJP_PL_na
static STRLEN UNIJP_PL_na;
#endif

#endif /* UNICODE__JAPANESE_H__ */
