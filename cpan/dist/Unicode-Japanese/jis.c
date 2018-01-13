
/* $Id$ */

#include "Japanese.h"
#include "sjis.h"

#include <string.h>

#define S2J_DISP 0
#define J2S_DISP 0

#if S2J_DISP
#define ECHO_S2J(arg) fprintf arg
#define ON_S2J(cmd) cmd
#else
#define ECHO_S2J(arg)
#define ON_S2J(cmd)
#endif
#if J2S_DISP
#define ECHO_J2S(arg) fprintf arg
#define ON_J2S(cmd) cmd
#else
#define ECHO_J2S(arg)
#define ON_J2S(cmd)
#endif

/*
#  JIS C 6226-1979  \e$@
#  JIS X 0208-1983  \e$B
#  JIS X 0208-1990  \e&@\e$B
#  JIS X 0212-1990  \e$(D
*/

#define JIS_C6226_1979 ((const unsigned char*)"\x1b$@")
#define JIS_X0208_1983 ((const unsigned char*)"\x1b$B")
#define JIS_X0208_1990 ((const unsigned char*)"\x1b&@\x1b$B")
#define JIS_X0212_1990 ((const unsigned char*)"\x1b$(D")

#define JIS_ASC  ((const unsigned char*)"\x1b(B")
#define JIS_ROMAN ((const unsigned char*)"\x1b(J")
#define JIS_KANA ((const unsigned char*)"\x1b(I")

#define JIS_C6226_1979_LEN 3
#define JIS_X0208_1983_LEN 3
#define JIS_X0208_1990_LEN 6
#define JIS_X0212_1990_LEN 4

#define JIS_ASC_LEN  3
#define JIS_ROMAN_LEN  3
#define JIS_KANA_LEN 3

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
/* sjis=>jis変換 */
EXTERN_C
SV*
xs_sjis_jis(SV* sv_str)
{
  unsigned char* src;
  STRLEN len;
  SV_Buf result;
  int esc_asc;
  const unsigned char* src_end;

  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
  {
    return newSVsv(&PL_sv_undef);
  }
  
  src = (unsigned char*)SvPV(sv_str, len);
  ECHO_S2J((stderr,"Unicode::Japanese::(xs)sjis_jis, len:%d\n",len));
  ON_S2J(bin_dump("in ",src,len));
  SV_Buf_init(&result,len+8);
  esc_asc = 1;
  src_end = src+len;

  while( src<src_end )
  {
    ECHO_S2J((stderr, "switch: %02x : %d\n", *src, chk_sjis[*src]));
    switch(chk_sjis[*src])
    {
    case CHK_SJIS_THROUGH:
      { /* SJIS:THROUGH => JIS:ASCII */
	const unsigned char* begin;
	if( !esc_asc )
	{
	  SV_Buf_append_mem(&result,JIS_ASC,JIS_ASC_LEN);
	  esc_asc = 1;
	}
#if TEST && S2J_DISP
	fprintf(stderr,"  (throuh) %c[%02x]",*src,*src);
	fflush(stderr);
#endif
	begin = src;
	while( ++src<src_end && chk_sjis[*src]==CHK_SJIS_THROUGH )
	{
#if TEST && S2J_DISP
	  fprintf(stderr," %c[%02x]",*src,*src);
	  fflush(stderr);
#endif
	}
#if TEST && S2J_DISP
	fprintf(stderr,"\n");
	fflush(stderr);
#endif
	SV_Buf_append_mem(&result,begin,src-begin);
	break;
      }
    case CHK_SJIS_C:
      {
	SV_Buf_append_mem(&result,JIS_X0208_1983,JIS_X0208_1983_LEN);
	esc_asc = 0;
	ECHO_S2J((stderr,"  (sjis:c)"));
	do
	{
	  unsigned char tmp[2];
	  ECHO_S2J((stderr, "%c%c[%02x.%02x]",src[0],src[1],src[0],src[1]));
	  if( src[1]<0x40 || 0xfc<src[1] || src[1]==0x7f )
	  {
	    ECHO_S2J((stderr, "*"));
	    SV_Buf_append_mem(&result,UNDEF_JIS,UNDEF_JIS_LEN);
	    ++src;
	    break;
	  }
	  if( 0x9f <= src[1] )
	  {
	    tmp[0] = src[0]*2 - (src[0]>=0xe0 ? 0xe0 : 0x60);
	    tmp[1] = src[1] + 2;
	  }else
	  {
	    tmp[0] = src[0]*2 - (src[0]>=0xe0 ? 0xe1 : 0x61);
	    tmp[1] = src[1] + 0x60 + (src[1] < 0x7f);
	  }
	  tmp[0] &= 0x7f;
	  tmp[1] &= 0x7f;
	  SV_Buf_append_ch2(&result,*(UJ_UINT16*)tmp);
	  src += 2;
	}while( src<src_end && chk_sjis[*src]==CHK_SJIS_C );
	ECHO_S2J((stderr,"\n"));
	break;
      }
    case CHK_SJIS_KANA:
      { /* SJIS:KANA => JIS:KANA */
	SV_Buf_append_mem(&result,JIS_KANA,JIS_KANA_LEN);
	esc_asc = 0;
#if TEST && S2J_DISP
	fprintf(stderr,"  (sjis:kana)");
	fflush(stderr);
#endif
        do
	{
#if TEST && S2J_DISP
	  fprintf(stderr," %02x",*src);
	  fflush(stderr);
#endif
	  SV_Buf_append_ch(&result,*src&0x7f);
	}while( ++src<src_end && chk_sjis[*src]==CHK_SJIS_KANA );
#if TEST && S2J_DISP
	fprintf(stderr,"\n");
#endif
	break;
      }
    default:
      {
#ifdef TEST
	fprintf(stderr,"xs_sjis_eucjp, unknown check-code[%02x] on char-code[%05x]\n",chk_sjis[*src],*src);
#endif
	SV_Buf_append_ch(&result,*src);
	++src;
      }
    } /*switch */
  } /*while */

  if( !esc_asc )
  {
    SV_Buf_append_mem(&result,JIS_ASC,JIS_ASC_LEN);
  }
  /* bin_dump("out",SV_Buf_getBegin(&result),SV_Buf_getLength(&result)); */
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
/* jis=>sjis変換 */
EXTERN_C
SV*
xs_jis_sjis(SV* sv_str)
{
  unsigned char* src;
  STRLEN len;
  SV_Buf result;
  const unsigned char* src_end;

  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
  {
    return newSVsv(&PL_sv_undef);
  }
  
  src = (unsigned char*)SvPV(sv_str, len);
  ECHO_J2S((stderr,"Unicode::Japanese::(xs)jis_sjis, len:%d\n",len));
  ON_J2S(bin_dump("in ",src,len));
  SV_Buf_init(&result,len);
  src_end = src+len;
  
  if( len!=0 && *src!='\x1b' )
  {
    const unsigned char* begin = src;
    while( ++src<src_end && *src!='\x1b')
    {
    }
    SV_Buf_append_mem(&result,begin,src-begin);
  }
  while( src<src_end )
  {
    ECHO_J2S((stderr,"  len: %d\n",src_end-src));
    if( src_end-src>=JIS_ASC_LEN && memcmp(src,JIS_ASC,JIS_ASC_LEN)==0 )
    { /* <<jis.asc>> */
      const unsigned char* begin;
      /*fprintf(stderr,"  <jis.asc>\n"); */
      src += JIS_ASC_LEN;
      begin = src;
      while( src<src_end && *src!='\x1b')
      {
	++src;
      }
      if( src!=begin )
      {
	SV_Buf_append_mem(&result,begin,src-begin);
      }
    }else if( src_end-src>=JIS_ROMAN_LEN && memcmp(src,JIS_ROMAN,JIS_ROMAN_LEN)==0 )
    { /* <<jis.roman>> */
      const unsigned char* begin;
      /*fprintf(stderr,"  <jis.roman>\n"); */
      src += JIS_ROMAN_LEN;
      begin = src;
      while( src<src_end && *src!='\x1b')
      {
	++src;
      }
      if( src!=begin )
      {
	SV_Buf_append_mem(&result,begin,src-begin);
      }
    }else if( src_end-src>=JIS_KANA_LEN && memcmp(src,JIS_KANA,JIS_KANA_LEN)==0 )
    { /* <<jis.kana>> */
      /*fprintf(stderr,"  <jis.kana>\n"); */
      src += JIS_KANA_LEN;
      while( src<src_end && *src!='\x1b')
      {
	SV_Buf_append_ch(&result,*src|0x80);
	++src;
      }
    }else if( (src_end-src>=JIS_X0208_1983_LEN && memcmp(src,JIS_X0208_1983,JIS_X0208_1983_LEN)==0)
              || (src_end-src>=JIS_X0208_1990_LEN && memcmp(src,JIS_X0208_1990,JIS_X0208_1990_LEN)==0)
              || (src_end-src>=JIS_C6226_1979_LEN && memcmp(src,JIS_C6226_1979,JIS_C6226_1979_LEN)==0)
              )
    { /* <<jis.0208/0212>> */
      ECHO_J2S((stderr,"  <jis.c>");fflush(stderr));
      src += src[1]!='&' ? 3 : 6;
      while( src<src_end )
      {
	unsigned char tmp[2];
	if( *src=='\x1b' ) break;
	ECHO_J2S((stderr," %02x",src[0]);fflush(stderr));
        if( *src>=0x21 && *src<0x7e )
        {}else
        {
	  ECHO_J2S((stderr,"+");fflush(stderr));
          break;
        }
        if( src+1==src_end || src[1]=='\x1b' )
	{
	  ECHO_J2S((stderr,"*");fflush(stderr));
	  break;
	}
	ECHO_J2S((stderr," %02x",src[0]);fflush(stderr));
	tmp[0] = src[0] | 0x80;
	tmp[1] = src[1] | 0x80;
	if( src[0]%2 )
	{
	  tmp[0] = (tmp[0]>>1) + (tmp[0] < 0xdf ? 0x31 : 0x71);
	  tmp[1] = tmp[1] - ( 0x60 + (tmp[1] < 0xe0) );
	}else
	{
	  tmp[0] = (tmp[0]>>1) + (tmp[0] < 0xdf ? 0x30 : 0x70);
	  tmp[1] = tmp[1] - 2;
	}
	SV_Buf_append_ch2(&result,*(UJ_UINT16*)tmp);
	src += 2;
      }
      ECHO_J2S((stderr,"\n"));
    }else if( src_end-src>=JIS_X0212_1990_LEN && memcmp(src,JIS_X0212_1990,JIS_X0212_1990_LEN)==0 )
    { /* <<jis.0212>> */
      const unsigned char* begin;
      int i;
      ECHO_J2S((stderr,"  <jis.0212>");fflush(stderr));
      src += JIS_X0212_1990_LEN;
      begin = src;
      while( src<src_end && *src!='\x1b')
      {
	++src;
      }
      for( i=0; i<(src-begin)/2; ++i )
      {
	SV_Buf_append_mem(&result,UNDEF_SJIS,UNDEF_SJIS_LEN);
      }
    }else if( src[0]!='\x1b') /* !='\e' */
    { /* <<no escape>> */
      const unsigned char* begin;
      ECHO_J2S((stderr,"  <no.escape>");fflush(stderr));
      begin = src;
      while( src<src_end && *src!='\x1b')
      {
	++src;
      }
      if( src!=begin )
      {
	SV_Buf_append_mem(&result,begin,src-begin);
      }
    }else
    { /* <<unknown escape>> */
      ECHO_J2S((stderr,"  <escape.unknown>");fflush(stderr));
      SV_Buf_append_ch(&result,*src);
      ++src;
    }
  } /*while */

  ON_J2S(bin_dump("out",SV_Buf_getBegin(&result), SV_Buf_getLength(&result)));
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}
