
// $Id: getcode.cpp,v 1.4 2002/07/01 00:17:02 hio Exp $

#include "Japanese.h"
#include "getcode.h"

#define GC_DISP 0

// 文字コード定数
enum charcode_t
{
  cc_unknown,
  cc_ascii,
  cc_sjis,
  cc_eucjp,
  cc_jis,
  cc_utf8,
  cc_utf32,
  cc_utf32_be,
  cc_utf32_le,
  cc_sjis_jsky,
  cc_sjis_imode,
  cc_sjis_doti,
  cc_last,
};

// 文字コード名文字列(SV*)
#define new_CC_UNKNOWN()  newSVpvn("unknown",7)
#define new_CC_ASCII()    newSVpvn("ascii",  5)
#define new_CC_SJIS()     newSVpvn("sjis",   4)
#define new_CC_JIS()      newSVpvn("jis",    3)
#define new_CC_EUCJP()    newSVpvn("euc",    3)
#define new_CC_UTF8()     newSVpvn("utf8",   4)
#define new_CC_UTF16()    newSVpvn("utf16",  5)
#define new_CC_UTF32()    newSVpvn("utf32",  5)
#define new_CC_UTF32_BE() newSVpvn("utf32-be",8)
#define new_CC_UTF32_LE() newSVpvn("utf32-le",8)
#define new_CC_SJIS_JSKY()  newSVpvn("sjis-jsky",9)
#define new_CC_SJIS_IMODE() newSVpvn("sjis-imode",10)
#define new_CC_SJIS_DOTI()  newSVpvn("sjis-doti",9)

// 
#define RE_BOM2_BE  "\xfe\xff"
#define RE_BOM2_LE  "\xff\xfe"
#define RE_BOM4_BE  "\x00\x00\xfe\xff"
#define RE_BOM4_LE  "\xff\xfe\x00\x00"

#if defined(TEST) || 1
// 文字コード定数を文字コード名に
static const char* charcodeToStr(charcode_t code)
{
  switch(code)
  {
  case cc_unknown:  return "unknown";
  case cc_ascii:    return "ascii";
  case cc_sjis:     return "sjis";
  case cc_eucjp:    return "eucjp";
  case cc_jis:      return "jis";
  case cc_utf8:     return "utf8";
  case cc_utf32:    return "utf32";
  case cc_utf32_be: return "utf32-be";
  case cc_utf32_le: return "utf32-le";
  case cc_sjis_jsky:  return "sjis-jsky";
  case cc_sjis_imode: return "sjis-imode";
  case cc_sjis_doti:  return "sjis-doti";
  }
  return NULL;
}
#endif
#ifdef TEST
DECL_MAP_MODE(ascii,1) = { "ascii", };
DECL_MAP_MODE(eucjp,5) =
{ "eucjp", "0212:3.1","0212:3.2","c:2.1","kana:2.1",};
DECL_MAP_MODE(sjis,2) = { "sjis","c:2.1", };
DECL_MAP_MODE(jis,10) =
{
  "jis","jis#1","jis#2","jis#3","jis#4","jis#5","jis#6",
  "jis#7","jis#loop1","jis#loop2",
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
#endif

// 文字コード判定時に使用する構造体
struct CodeCheck
{
  charcode_t code;
  const unsigned char* base;
  const unsigned char* table;
#ifdef TEST
  const char** msg;
#endif
};

// 文字コード判定の初期状態
#ifndef TEST
#define GEN_CODE(name) \
  { cc_##name, (const unsigned char*)map_##name, (const unsigned char*)map_##name, }
#else
#define GEN_CODE(name) \
  { cc_##name, (const unsigned char*)map_##name, (const unsigned char*)map_##name, mode_##name, }
#endif
#define cc_tmpl_max 10
const CodeCheck cc_tmpl[] = 
{
  GEN_CODE(ascii),
  GEN_CODE(eucjp),
  GEN_CODE(sjis),
  GEN_CODE(jis),
  GEN_CODE(utf8),
  GEN_CODE(utf32_be),
  GEN_CODE(utf32_le),
  GEN_CODE(sjis_jsky),
  GEN_CODE(sjis_imode),
  GEN_CODE(sjis_doti),
};

// 判定結果の構造体
struct CodeResult
{
  charcode_t code;
  int begin;
  int len;
};

// 複数候補から１つを選択
int choice_one(CodeCheck* check, int cc_max)
{
  charcode_t order[cc_tmpl_max] = 
  {
    cc_utf32_be,
    cc_utf32_le,
    cc_ascii,
    cc_jis,
    cc_eucjp,
    cc_sjis,
    cc_sjis_jsky,
    cc_sjis_imode,
    cc_sjis_doti,
    cc_utf8,
  };
  for( int cc=0; cc<cc_tmpl_max; ++cc )
  {
    for( int i=0; i<cc_max; ++i )
    {
      if( check[i].code==order[cc] )
      {
	return i;
      }
    }
  }
  return 0;
}

// getcode関数
SV* xs_getcode(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return new_SV_UNDEF();
  }
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);
  const unsigned char* src_end = src+len;
  if( len==0 )
  {
    return new_CC_UNKNOWN();
  }
  if( (len%4)==0 && len>=4 &&
      ( memcmp(src,RE_BOM4_BE,4)==0 || memcmp(src,RE_BOM4_LE,4)==0 ) )
  {
    return new_CC_UTF32();
  }
  if( (len%2)==0 && len>=2 &&
      ( memcmp(src,RE_BOM2_BE,2)==0 || memcmp(src,RE_BOM2_LE,2)==0 ) )
  {
    return new_CC_UTF16();
  }

  //fprintf(stderr,"Unicode::Japanese::(xs)getcode[%d]\n",len);
  //fprintf(stderr,">>%s<<\n",src);
  //bin_dump("in ",src,len);

  //asm volatile(".int 3");
  //SV_Buf result(len*3/2+4);

  CodeCheck check[cc_tmpl_max];
  memcpy(check,cc_tmpl,sizeof(cc_tmpl));
  int cc_max = cc_tmpl_max;

  for( ; src<src_end; ++src )
  {
#if TEST && GC_DISP
    fprintf(stderr,"[%d] %d (0x%02x)\n",len-(src_end-src),*src,*src);
#endif
    // 遷移を１つ進める〜
    int invalids = 0;
    for( int i=0; i<cc_max; ++i )
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
    { // 全部継続
      continue;
    }else if( cc_max-invalids>0 )
    { // まだあり〜
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
    { // 全部だめ〜
      return new_CC_UNKNOWN();
      break;
    }
  }

  int wr = 0;
  for( int i=0; i<cc_max; ++i )
  {
    if( check[i].table == check[i].base )
    {
      if( wr!=i )
      {
	check[wr] = check[i];
      }
      ++wr;
    }
  }
  cc_max = wr;

#if TEST && GC_DISP
  fprintf(stderr,"<availables>\n");
  for( int i=0; i<cc_max; ++i )
  {
    fprintf(stderr,"  %s\n",charcodeToStr(check[i].code));
  }
#endif

  int index = choice_one(check,cc_max);
#if TEST && GC_DISP
  fprintf(stderr,"<choice>\n  [%d/0..%d]\n",index,cc_max-1);
  fprintf(stderr,"<selected>\n");
  fprintf(stderr,"  %s\n",charcodeToStr(check[index].code));
#endif
  switch(check[index].code)
  {
  case cc_unknown:  return new_CC_UNKNOWN();
  case cc_ascii:    return new_CC_ASCII();
  case cc_sjis:     return new_CC_SJIS();
  case cc_eucjp:    return new_CC_EUCJP();
  case cc_jis:      return new_CC_JIS();
  case cc_utf8:     return new_CC_UTF8();
  //case cc_utf32:  return new_CC_UTF32();
  case cc_utf32_be: return new_CC_UTF32_BE();
  case cc_utf32_le: return new_CC_UTF32_LE();
  case cc_sjis_jsky: return new_CC_SJIS_JSKY();
  case cc_sjis_imode: return new_CC_SJIS_IMODE();
  case cc_sjis_doti: return new_CC_SJIS_DOTI();

  default:
#ifdef TEST
    return NULL;
#else
    return new_CC_UNKNOWN();
#endif
  }

}

