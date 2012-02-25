
/* $Id$ */

#include "Japanese.h"
#include <stdio.h>

#ifndef __cplusplus
#undef bool
#undef true
#undef false
typedef enum bool { false, true, } bool;
#endif

#define DISP_U2S 0
#define DISP_S2U 0

#if DISP_U2S
#define ECHO_U2S(arg) fprintf arg
#define ON_U2S(cmd) cmd
#else
#define ECHO_U2S(arg)
#define ON_U2S(cmd)
#endif
#if DISP_S2U
#define ECHO_S2U(arg) fprintf arg
#define ON_S2U(cmd) cmd
#else
#define ECHO_S2U(arg)
#define ON_S2U(cmd)
#endif

/* ----------------------------------------------------------------------------
 * SV* sv_utf8 = xs_sjis_jsky2_utf8(SV* sv_sjis)
 * convert sjis(jsky2) into utf8.
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_sjis_jsky2_utf8(SV* sv_str)
{
  STRLEN src_len;
  UJ_UINT8* src;
  int len;
  
  SV_Buf result;
  const UJ_UINT8* src_end;
  
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  
  src = (UJ_UINT8*)SvPV(sv_str,src_len);
  len = sv_len(sv_str);
#if DISP_S2U
  fprintf(stderr,"Unicode::Japanese::(xs)sjis_utf8_jsky2, len=%d\n",len);
  bin_dump("in ",src,len);
#endif
  SV_Buf_init(&result,len*3/2+4);
  src_end = src+len;

  while( src<src_end )
  {
    const UJ_UINT8* ptr;
    if( src[0]<0x80 )
    { /* ASCII */
      UJ_UINT8* begin;
      int j1;
      const UJ_UINT32* table;
      ECHO_U2S((stderr,"ascii: %02x\n",src[0]));
      
      if( src[0]!='\x1b' || src+2>=src_end || src[1]!='$' )
      { /* not emoji. */
	SV_Buf_append_ch(&result,*src);
	++src;
	continue;
      }
      /*fprint(stderr,"detect j-sky emoji-start escape\n"); */
      /* E_JSKY_1 */
      if( src[2]=='E' || src[2]=='F' || src[2]=='G' )
      {
        j1 = (src[2]-'E')<<8;
        table = g_ej2u1_table;
        ECHO_U2S((stderr,"src[2]: %02x '%c' j1:%04x\n",src[2],src[2],j1));
      }else if( src[2]=='O' || src[2]=='P' || src[2]=='Q' )
      {
	j1 = (src[2]-'O')<<8;
	table = g_ej2u2_table;
        ECHO_U2S((stderr,"src[2]: %02x '%c' j1:%04x\n",src[2],src[2],j1));
      }else
      {
	/*fprintf(stderr,"first char is invalid"); */
	SV_Buf_append_ch(&result,*src);
	++src;
	continue;
      }
      
      begin = src;
      src += 3;
      /* E_JSKY_2 */
      while( src<src_end )
      {
	if( '!'<=src[0] && src[0]<='z' )
	{
	  ++src;
	  continue;
	}
	break;
      }
      if( src<src_end && src[0]==0x0f )
      {
        /* accept, normally. */
      }else if( src==src_end )
      {
        /* accept, without terminator. */
      }else
      {
        /* invalid, rollback. */
        SV_Buf_append_ch(&result, '\x1b');
        src = begin+1;
        continue;
      }
      for( ptr = begin+3; ptr<src; ++ptr )
      {
	/*fprintf(stderr," <%c%c:%04x>\n",begin[2],*ptr,j1+*ptr); */
	/*fprintf(stderr,"   => %04x\n",g_ej2u2_table[j1+*ptr]); */
	const UJ_UINT8* str = (UJ_UINT8*)&table[j1+*ptr];
	/*fprintf(stderr,"   len: %d\n",str[3]?4:strlen((char*)str)); */
	SV_Buf_append_mem(&result,str,str[3]?4:strlen((char*)str));
      }
      /*fprintf(stderr,"j-sky string done.\n"); */
      
      /* '\x0f' をスキップ. */
      /* src==src_end の時はバッファを超えるけど, */
      /* その時はこれ以上はアクセスしないので気にしない. */
      ++src;
      continue;
    }else if( 0xa1<=src[0] && src[0]<=0xdf )
    { /* half-width katakana (ja:半角カナ) */
      ECHO_U2S((stderr,"kana: %02x\n",src[0]));
      ptr = (UJ_UINT8*)&g_s2u_table[(src[0]-0xa1)*3];
      ++src;
    }else if( src+1<src_end && 0x81<=src[0] && src[0]<=0x9f )
    { /* a double-byte letter (ja:2バイト文字) */
      const UJ_UINT16 sjis = (src[0]<<8)+src[1]; /* ntohs */
      ECHO_U2S((stderr,"sjis.dbcs#1: %04x\n",sjis));
      ptr = (UJ_UINT8*)&g_s2u_table[(sjis - 0x8100 + 0x3f)*3];
      src += 2;
    }else if( src+1<src_end && 0xe0<=src[0] && src[0]<=0xfc )
    { /* a double-byte letter (ja:2バイト文字) */
      const UJ_UINT16 sjis = (src[0]<<8)+src[1]; /* ntohs */
      ECHO_U2S((stderr,"sjis.dbcs#2: %04x\n",sjis));
      ptr = (UJ_UINT8*)&g_s2u_table[(sjis- 0xe000 + 0x1f3f)*3];
      src += 2;
    }else
    { /* unknown */
      /*fprintf(stderr,"unknown: %02x\n",src[0]); */
      SV_Buf_append_ch(&result,'?');
      ++src;
      continue;
    }

    ECHO_U2S((stderr,"offset: 0x%04x\n",ptr-g_s2u_table));
    ECHO_U2S((stderr,"utf8-char : %02x %02x %02x\n",ptr[0],ptr[1],ptr[2]));
    if( ptr[2] )
    {
      /*fprintf(stderr,"utf8-len: [%d]\n",3); */
      SV_Buf_append_mem(&result, ptr, 3);
    }else if( ptr[1] )
    {
      /*fprintf(stderr,"utf8-len: [%d]\n",2); */
      SV_Buf_append_mem(&result, ptr, 2);
    }else if( ptr[0] )
    {
      /*fprintf(stderr,"utf8-len: [%d]\n",1); */
      SV_Buf_append_ch(&result,*ptr);
    }else
    {
      SV_Buf_append_ch(&result,'?');
    }
  }
  ON_S2U( bin_dump("out",SV_Buf_getBegin(&result),SV_Buf_getLength(&result)) );
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}

/* ---------------------------------------------------------------------------
 * utf8 ==> jsky2
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_utf8_sjis_jsky2(SV* sv_str)
{
  UJ_UINT8* src;
  int len;
  SV_Buf result;
  const UJ_UINT8* src_end;

  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  src = (UJ_UINT8*)SvPV(sv_str,PL_na);
  len = sv_len(sv_str);

  ECHO_U2S((stderr,"Unicode::Japanese::(xs)utf8_sjis_jsky2\n"));
  ON_U2S( bin_dump("in ",src,len) );

  SV_Buf_init(&result,len+4);
  src_end = src+len;

  while( src<src_end )
  {
    UJ_UINT32 ucs;
    const UJ_UINT8* sjis_ptr;
    
    if( *src<=0x7f )
    {
      /* ascii chars sequence (ja:ASCIIはまとめて追加〜) */
      int len = 1;
      while( src+len<src_end && src[len]<=0x7f )
      {
        ++len;
      }
      SV_Buf_append_mem(&result,src,len);
      src+=len;
      continue;
    }
    
    /* non-ascii */
    if( 0xe0<=*src && *src<=0xef )
    { /* 3byte range. mostly enter here. */
      const int       utf8_len = 3;
      const UJ_UINT32 ucs_min  = 0x800;
      const UJ_UINT32 ucs_max  = 0xffff;
      ECHO_U2S((stderr,"utf8-len: [%d]\n",utf8_len));
      /* check length */
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf && 0x80<=src[2] && src[2]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      
      /* compute code point */
      ucs = ((src[0] & 0x0F)<<12)|((src[1] & 0x3F)<<6)|(src[2] & 0x3F);
      src += utf8_len;
      if( ucs_min<=ucs && ucs<=ucs_max )
      { /* noop */
      }else
      { /* illegal sequence */
        SV_Buf_append_ch(&result,'?');
        continue;
      }
      /* ok. */
    }else if( 0xf0<=*src && *src<=0xf7 )
    {
      const int       utf8_len = 4;
      const UJ_UINT32 ucs_min  = 0x010000;
      const UJ_UINT32 ucs_max  = 0x10ffff;
      ECHO_U2S((stderr,"utf8-len: [%d]\n",utf8_len));
      /* check length */
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf && 0x80<=src[2] && src[2]<=0xbf
          && 0x80<=src[3] && src[3]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      
      /* compute code point */
      ucs = ((src[0] & 0x07)<<18)|((src[1] & 0x3F)<<12)|
        ((src[2] & 0x3f) << 6)|(src[3] & 0x3F);
      src += utf8_len;
      if( ucs_min<=ucs && ucs<=ucs_max )
      { /* noop */
      }else
      { /* illegal sequence */
        SV_Buf_append_ch(&result,'?');
        continue;
      }
      /* private area: block emoji */ 
      if( 0x0f0000<=ucs && ucs<=0x0fffff )
      {
        const UJ_UINT8* sjis;
        if( ucs<0x0fe000 )
        { /* unknown area. */
	  SV_Buf_append_ch(&result,'?');
	  continue;
        }
        /* j-sky2 emoji */
        sjis = &g_eu2j2_table[(ucs - 0x0fe000)*5];
        /*fprintf(stderr,"  emoji: %02x %02x %02x %02x %02x\n", */
        /*	  sjis[0],sjis[1],sjis[2],sjis[3],sjis[4]); */
        if( sjis[4]!=0 )
        { /* 5 bytes */
	  SV_Buf_append_ch5(&result,sjis);
        }else if( sjis[3]!=0 )
        { /* 4 bytes. */
	  assert("not reach here" && 0);
	  SV_Buf_append_mem(&result, sjis, 4);
        }else if( sjis[2]!=0 )
        { /* 3 bytes. */
	  assert("not reach here" && 0);
	  SV_Buf_append_mem(&result, sjis, 3);
        }else if( sjis[1]!=0 )
        { /* 2 bytes. */
	  SV_Buf_append_mem(&result, sjis, 2);
        }else if( sjis[0]!=0 )
        { /* 1 byte. */
	  SV_Buf_append_ch(&result,*sjis);
        }else
        { /* no mapping */
          SV_Buf_append_ch(&result,'?');
        }
        continue;
      }
      
      /* > U+10FFFF not supported by UTF-8 (RFC 3629). */
      if( ucs>0x10FFFF )
      {
        SV_Buf_append_ch(&result,'?');
        continue;
      }
    }else if( 0xc0<=*src && *src<=0xdf )
    {
      const int       utf8_len = 2;
      const UJ_UINT32 ucs_min  =  0x80;
      const UJ_UINT32 ucs_max  = 0x7ff;
      ECHO_U2S((stderr,"utf8-len: [%d]\n",utf8_len));
      /* check length */
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      
      /* compute code point */
      ucs = ((src[0] & 0x1F)<<6)|(src[1] & 0x3F);
      src += utf8_len;
      if( ucs_min<=ucs && ucs<=ucs_max )
      { /* noop */
      }else
      { /* illegal sequence */
        SV_Buf_append_ch(&result,'?');
        continue;
      }
      
      /* ok. */
    }else if( 0xf8<=*src && *src<=0xfb )
    {
      const int          utf8_len = 5;
      ECHO_U2S((stderr,"utf8-len: [%d]\n",utf8_len));
      /* check length */
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf && 0x80<=src[2] && src[2]<=0xbf
          && 0x80<=src[3] && src[3]<=0xbf && 0x80<=src[4] && src[4]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      
      /* compute code point */
      /* > U+10FFFF not supported by UTF-8 (RFC 3629). */
      src += utf8_len;
      SV_Buf_append_ch(&result,'?');
      continue;
    }else if( 0xfc<=*src && *src<=0xfd )
    {
      const int          utf8_len = 6;
      ECHO_U2S((stderr,"utf8-len: [%d]\n",utf8_len));
      /* check length */
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf && 0x80<=src[2] && src[2]<=0xbf
          && 0x80<=src[3] && src[3]<=0xbf && 0x80<=src[4] && src[4]<=0xbf
          && 0x80<=src[5] && src[5]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch(&result,'?');
        ++src;
        continue;
      }
      
      /* compute code point */
      /* > U+10FFFF not supported by UTF-8 (RFC 3629). */
      src += utf8_len;
      SV_Buf_append_ch(&result,'?');
      continue;
    }else
    {
      SV_Buf_append_ch(&result,'?');
      ++src;
      continue;
    }
    
    /* ucs => sjis */
    ECHO_U2S((stderr,"ucs [%04x]\n",ucs));
    if( ucs<=0x9FFF ) 
    {
      sjis_ptr = g_u2s_table + ucs*2;
    }else if( 0xF900<=ucs && ucs<=0xFFFF )
    {
      sjis_ptr = g_u2s_table + (ucs - 0xF900 + 0xA000)*2;
    }else if( 0x0FE000<=ucs && ucs<=0x0FFFFF )
    {
      sjis_ptr = (UJ_UINT8*)"?"; /* exactly 2byte: "?\0" */
    }else
    {
      sjis_ptr = (UJ_UINT8*)"\0"; /* exactly 2byte: "\0\0" */
    }
    if( sjis_ptr[0]!=0 || sjis_ptr[1]!=0 )
    { /* mapping dest exists. */
      if( sjis_ptr[1]!=0 )
      {
        SV_Buf_append_mem(&result, sjis_ptr, 2);
      }else
      {
        SV_Buf_append_ch(&result,sjis_ptr[0]);
      }
    }else if( ucs<=0x7F )
    {
      SV_Buf_append_ch(&result,(UJ_UINT8)ucs);
    }else
    {
      SV_Buf_append_ch(&result,'?');
    }
  } /* while */

  ON_U2S( bin_dump("out",SV_Buf_getBegin(&result),SV_Buf_getLength(&result)) );
  SV_Buf_setLength(&result);

  sv_2mortal(SV_Buf_getSv(&result));
  {
  /* packing J-SKY emoji escapes */
  SV_Buf pack;
  UJ_UINT8* ptr;
  UJ_UINT8 tmpl[5] = { '\x1b','$',0,0,'\x0f',};
  
  SV_Buf_init(&pack,SV_Buf_getLength(&result));
  src = SV_Buf_getBegin(&result);
  src_end = src + SV_Buf_getLength(&result);
  ptr = src;
  for( ; src+5*2-1<src_end; ++src )
  {
    UJ_UINT8 ch1;
    /* E_JSKY_START  "\x1b\$", */
    if( src[0]!='\x1b' ) continue;
    if( src[1]!='$' ) continue;
    /* E_JSKY1   '[EFG]', */
    /*fprintf(stderr,"  found emoji-start\n"); */
    if( src[2]!='E' && src[2]!='F' && src[2]!='G'
        && src[2]!='O' && src[2]!='P' && src[2]!='Q' )
    {
      /*fprintf(stderr,"  invalid ch1 [%x:%02x]\n",src[2],src[2]); */
      continue;
    }
    ch1 = src[2];
    /* E_JSKY2    '[\!-\;\=-z\xbc]', */
    if( src[3]<'!' || 'z'<src[3] )
    {
      /*fprintf(stderr,"  invalid ch2 [%02x]\n",src[3]); */
      continue;
    }
    /* E_JSKY_END    "\x0f", */
    if( src[4]!='\x0f' ) continue;

    /*fprintf(stderr,"  found first emoji [%02x:%c]\n",ch1,ch1); */
    src += 5;
    SV_Buf_append_mem(&pack,ptr,(src-1)-ptr);
    tmpl[2] = ch1;
    for( ; src_end-src>=5; src+= 5 )
    {
      tmpl[3] = src[3];
      if( memcmp(src,tmpl,5)!=0 ) break;
      /*fprintf(stderr,"  packing...[%02x]\n",src[3]); */
      SV_Buf_append_ch(&pack,src[3]);
    }
    /*fprintf(stderr,"  pack done.\n"); */
    SV_Buf_append_ch(&pack,'\x0f');
    ptr = src;
  }
  /*fprintf(stderr,"  pack complete.\n"); */
  /*fprintf(stderr,"  append len %0d\n",src_end-ptr); */
  if( ptr!=src_end )
  {
    SV_Buf_append_mem(&pack,ptr,src_end-ptr);
  }

  ON_U2S( bin_dump("out",SV_Buf_getBegin(&pack),SV_Buf_getLength(&pack)) );
  SV_Buf_setLength(&pack);

  return SV_Buf_getSv(&pack);
  }
}
