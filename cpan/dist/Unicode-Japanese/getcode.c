
/* $Id$ */

#include "Japanese.h"
#include "getcode.h"

#include <string.h>

#ifndef dAX
/* 5.6.x? */
#define dAX I32 ax = MARK - PL_stack_base + 1
#endif

#define PERL_PATCHLEVEL_H_IMPLICIT
#include "patchlevel.h"

#if !defined(PERL_VERSION)  && defined(PATCHLEVEL)
/* 5.005_xx and prior */
#define PERL_REVISION   5
#define PERL_VERSION    PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif

#if PERL_VERSION <= 4 && !defined(PL_stack_base)
/* 5.004 */
extern SV ** Perl_stack_base;
#define PL_stack_base Perl_stack_base
#endif

#define GC_DISP 0

#ifndef __cplusplus
#undef bool
#undef true
#undef false
typedef enum bool { false, true, } bool;
#endif

/* 文字コード定数 */
enum charcode_t
{
  cc_unknown,
  cc_ascii,
  cc_sjis,
  cc_eucjp,
  cc_jis_au,
  cc_jis_jsky,
  cc_jis,
  cc_utf8,
  cc_utf16,
  cc_utf32,
  cc_utf32_be,
  cc_utf32_le,
  cc_sjis_jsky,
  cc_sjis_au,
  cc_sjis_imode,
  cc_sjis_doti,
  cc_last,
};
typedef enum charcode_t charcode_t;

/* 文字コード名文字列(SV*) */
#define new_CC_UNKNOWN()  newSVpvn("unknown", 7)
#define new_CC_ASCII()    newSVpvn("ascii",   5)
#define new_CC_SJIS()     newSVpvn("sjis",    4)
#define new_CC_JIS_AU()   newSVpvn("jis-au",  6)
#define new_CC_JIS_JSKY() newSVpvn("jis-jsky",8)
#define new_CC_JIS()      newSVpvn("jis",     3)
#define new_CC_EUCJP()    newSVpvn("euc",     3)
#define new_CC_UTF8()     newSVpvn("utf8",    4)
#define new_CC_UTF16()    newSVpvn("utf16",   5)
#define new_CC_UTF32()    newSVpvn("utf32",   5)
#define new_CC_UTF32_BE() newSVpvn("utf32-be",8)
#define new_CC_UTF32_LE() newSVpvn("utf32-le",8)
#define new_CC_SJIS_JSKY()  newSVpvn("sjis-jsky",9)
#define new_CC_SJIS_IMODE() newSVpvn("sjis-imode",10)
#define new_CC_SJIS_DOTI()  newSVpvn("sjis-doti",9)
#define new_CC_SJIS_AU()    newSVpvn("sjis-au",7)

/* */
#define RE_BOM2_BE  "\xfe\xff"
#define RE_BOM2_LE  "\xff\xfe"
#define RE_BOM4_BE  "\x00\x00\xfe\xff"
#define RE_BOM4_LE  "\xff\xfe\x00\x00"

#if defined(TEST) && GC_DISP
/* 文字コード定数を文字コード名に. */
static const char* charcodeToStr(charcode_t code)
{
  switch(code)
  {
  case cc_unknown:  return "unknown";
  case cc_ascii:    return "ascii";
  case cc_sjis:     return "sjis";
  case cc_eucjp:    return "eucjp";
  case cc_jis_au:   return "jis-au";
  case cc_jis_jsky: return "jis-jsky";
  case cc_jis:      return "jis";
  case cc_utf8:     return "utf8";
  case cc_utf32:    return "utf32";
  case cc_utf32_be: return "utf32-be";
  case cc_utf32_le: return "utf32-le";
  case cc_sjis_jsky:  return "sjis-jsky";
  case cc_sjis_imode: return "sjis-imode";
  case cc_sjis_doti:  return "sjis-doti";
  case cc_sjis_au:    return "sjis-au";
  default: return NULL;
  }
}
#endif
#ifdef TEST
DECL_MAP_MODE(ascii,1) = { "ascii", };
DECL_MAP_MODE(eucjp,5) =
{ "eucjp", "0212:3.1","0212:3.2","c:2.1","kana:2.1",};
DECL_MAP_MODE(sjis,2) = { "sjis","c:2.1", };
DECL_MAP_MODE(jis,11) =
{
  "jis","jis#1","jis#2","jis#3","jis#4","jis#5","jis#6",
  "jis#7","jis#loop1","jis#loop2","jis#kana",
};
DECL_MAP_MODE(jis_au,12) =
{
  "jis","jis#1","jis#2","jis#3","jis#4","jis#5","jis#6",
  "jis#7","jis#loop1","jis#loop2","jis#kana","jis#au",
};
DECL_MAP_MODE(jis_jsky,13) =
{
  "jis","jis#1","jis#2","jis#3","jis#4","jis#5","jis#6",
  "jis#7","jis#loop1","jis#loop2","jis#kana","jis#j2","jis#jend",
};
DECL_MAP_MODE(utf8,6) = 
{
  "utf8",
  "u8:6.1","u8:6.2","u8:6.3","u8:6.4","u8:6.5",
};
DECL_MAP_MODE(utf32_be,4) = 
{
  "utf32-be","utf32-be:4:1","utf32-be:4:2","utf32-be:4:3",
};
DECL_MAP_MODE(utf32_le,4) = 
{
  "utf32-le","utf32-le:4:1","utf32-le:4:2","utf32-le:4:3",
};
DECL_MAP_MODE(sjis_jsky,5) =
{
  "sjis","c:2.1",
  "jsky:start:1","jsky:start:2","jsky:code1",
};
DECL_MAP_MODE(sjis_imode,4) =
{
  "sjis","c:2.1",
  "imode1:1","imode2:1",
};
DECL_MAP_MODE(sjis_doti,7) =
{
  "sjis","c:2.1",
  "doti1:1", "doti2:1", "doti3:1", "doti4:1", "doti5:1",
};
DECL_MAP_MODE(sjis_au,3) =
{
  "sjis","c:2.1",
  "au:1",
};
#endif

/* 文字コード判定時に使用する構造体. */
struct CodeCheck
{
  charcode_t code;
  const unsigned char* base;
  const unsigned char* table;
#ifdef TEST
  const char** msg;
#endif
};
typedef struct CodeCheck CodeCheck;

/* 文字コード判定の初期状態. */
#ifndef TEST
#define GEN_CODE(name) \
  { cc_##name, (const unsigned char*)map_##name, (const unsigned char*)map_##name, }
#else
#define GEN_CODE(name) \
  { cc_##name, (const unsigned char*)map_##name, (const unsigned char*)map_##name, mode_##name, }
#endif
#define cc_tmpl_max 13
const CodeCheck cc_tmpl[cc_tmpl_max] = 
{
  GEN_CODE(utf32_be),
  GEN_CODE(utf32_le),
  GEN_CODE(ascii),
  GEN_CODE(jis),
  GEN_CODE(jis_au),
  GEN_CODE(jis_jsky),
  GEN_CODE(eucjp),
  GEN_CODE(sjis),
  GEN_CODE(sjis_jsky),
  GEN_CODE(sjis_imode),
  GEN_CODE(sjis_au),
  GEN_CODE(sjis_doti),
  GEN_CODE(utf8),
};

/* 判定結果の構造体. */
struct CodeResult
{
  charcode_t code;
  int begin;
  int len;
};
typedef struct CodeResult CodeResult;

static bool _is_acceptable_state(const CodeCheck* check)
{
  /* special cases. */
  if( check->table==map_jis_jsky[11] )
  { /* jis-jsky, jis#j2 */
    return true;
  }
  if( check->table==map_sjis_jsky[4] )
  { /* sjis-jsky, sjis#j2 */
    return true;
  }
  return false;
}

static int getcode_list(SV* sv_str, CodeCheck* check)
{
  unsigned char* src;
  STRLEN len;
  const unsigned char* src_end;
  int cc_max;
  
  if( sv_str==&PL_sv_undef )
  {
    return 0;
  }
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
  {
    return 0;
  }
  
  src = (unsigned char*)SvPV(sv_str, len);
  src_end = src+len;
  
  /* empty string */
  /* (jp:) 空文字列は unknown */
  if( len==0 )
  {
    return 0;
  }
  
  /* BOM of UTF32 */
  if( (len%4)==0 && len>=4 &&
      ( memcmp(src,RE_BOM4_BE,4)==0 || memcmp(src,RE_BOM4_LE,4)==0 ) )
  {
    check[0].code = cc_utf32;
    return 1;
  }
  
  /* BOM of UTF16 */
  if( (len%2)==0 && len>=2 &&
      ( memcmp(src,RE_BOM2_BE,2)==0 || memcmp(src,RE_BOM2_LE,2)==0 ) )
  {
    check[0].code = cc_utf16;
    return 1;
  }

  /* fprintf(stderr,"Unicode::Japanese::(xs)getcode[%d]\n",len); */
  /* fprintf(stderr,">>%s<<\n",src); */
  /* bin_dump("in ",src,len); */

  memcpy(check,cc_tmpl,sizeof(cc_tmpl));
  cc_max = cc_tmpl_max;

  for( ; src<src_end; ++src )
  {
    int invalids;
    int i;
#if TEST && GC_DISP
    fprintf(stderr,"[%d] '%c' 0x%02x (%d)\n",len-(src_end-src),(0x20<=*src&&*src<=0x7f?*src:'.'),*src,*src);
#endif
    /* 遷移を１つ進める〜 */
    invalids = 0;
    for( i=0; i<cc_max; ++i )
    {
      int nxt = check[i].table[*src];
#if TEST && GC_DISP
      fprintf(stderr,"  %s : %d (%s)\n",charcodeToStr(check[i].code),nxt,nxt!=map_invalid?check[i].msg[nxt]:"invalid");
#endif
      if( nxt!=map_invalid )
      {
	check[i].table = check[i].base+nxt*256;
      }else
      {
	++invalids;
	check[i].table = NULL;
      }
    }
    if( invalids==0 )
    { /* 全部継続 */
      continue;
    }else if( cc_max-invalids>0 )
    { /* まだあり〜 */
      int rd = 0;
      int wr = 0;
      for( ;rd<cc_max; ++rd )
      {
	if( check[rd].table )
	{
	  if( rd!=wr )
	  {
	    check[wr] = check[rd];
	  }
	  ++wr;
	}
      }
      cc_max = wr;
    }else
    { /* 全部だめ〜 */
      return 0;
    }
  }

  /* check if we have stopped at a valid (final?) state */
  {
    int wr = 0;
    int i;
    for( i=0; i<cc_max; ++i )
    {
      if( check[i].table == check[i].base || _is_acceptable_state(&check[i]) )
      {
        if( wr!=i )
	{
	  check[wr] = check[i];
	}
	++wr;
      }
    }
    cc_max = wr;
  }

#if TEST && GC_DISP
  fprintf(stderr,"<availables>\n");
  {
    int i;
    for( i=0; i<cc_max; ++i )
    {
      fprintf(stderr,"  %s\n",charcodeToStr(check[i].code));
    }
  }
#endif
  
  return cc_max;
}

#ifndef NO_XSUBS

/* getcode関数 */
SV* xs_getcode(SV* sv_str)
{
  int matches;
  CodeCheck check[cc_tmpl_max];
  
  if( sv_str==&PL_sv_undef )
  {
    return new_SV_UNDEF();
  }
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
  {
    return newSVsv(&PL_sv_undef);
  }
  matches = getcode_list(sv_str, check);
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
    case cc_unknown:    return new_CC_UNKNOWN();
    case cc_ascii:      return new_CC_ASCII();
    case cc_sjis:       return new_CC_SJIS();
    case cc_eucjp:      return new_CC_EUCJP();
    case cc_jis:        return new_CC_JIS();
    case cc_jis_au:     return new_CC_JIS_AU();
    case cc_jis_jsky:   return new_CC_JIS_JSKY();
    case cc_utf8:       return new_CC_UTF8();
    case cc_utf16:      return new_CC_UTF16();
    case cc_utf32:      return new_CC_UTF32();
    case cc_utf32_be:   return new_CC_UTF32_BE();
    case cc_utf32_le:   return new_CC_UTF32_LE();
    case cc_sjis_jsky:  return new_CC_SJIS_JSKY();
    case cc_sjis_imode: return new_CC_SJIS_IMODE();
    case cc_sjis_doti:  return new_CC_SJIS_DOTI();
    case cc_sjis_au:    return new_CC_SJIS_AU();
    
    default:
#ifdef TEST
      return NULL;
#else
      return new_CC_UNKNOWN();
#endif
    }
  }else
  {
    return new_CC_UNKNOWN();
  }
}

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
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
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
