/* ----------------------------------------------------------------------------
 * ucs4.c
 * ----------------------------------------------------------------------------
 * Mastering programed by YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */


#include "Japanese.h"

/* ----------------------------------------------------------------------------
 * convert ucs4 into utf-8
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_ucs4_utf8(SV* sv_str)
{
  UJ_UINT8* src;
  int len;
  SV_Buf result;
  const UJ_UINT8* src_end;
  UJ_UINT8 buf[4];

  if( sv_str==&PL_sv_undef )
  {
    return newSVpvn("",0);
  }
  
  src = (UJ_UINT8*)SvPV(sv_str,PL_na);
  len = sv_len(sv_str);
  src_end = src+(len&~1);
  /*fprintf(stderr,"Unicode::Japanese::(xs)ucs4_utf8\n",len);*/
  /*bin_dump("in ",src,len);*/
  SV_Buf_init(&result,len*3/2+4);

  if( len&3 )
  {
    Perl_croak(aTHX_ "Unicode::Japanese::ucs4_utf8, invalid length (not 4*n)");
  }

  for(; src<src_end; src+=4 )
  {
    const UJ_UINT32 ucs4 = (src[0]<<24)+(src[1]<<16)+(src[2]<<8)+src[3]; /* ntohs */
    if( ucs4<0x80 )
    {
      SV_Buf_append_ch(&result,(UJ_UINT8)ucs4);
    }else if( ucs4<0x800 )
    {
      buf[0] = 0xC0 | (ucs4 >> 6);
      buf[1] = 0x80 | (ucs4 & 0x3F);
      SV_Buf_append_mem(&result, buf, 2);
    }else if( ucs4 < 0x10000 )
    {
      buf[0] = 0xE0 | (ucs4 >> 12);
      buf[1] = 0x80 | ((ucs4 >> 6) & 0x3F);
      buf[2] = 0x80 | (ucs4 & 0x3F);
      SV_Buf_append_mem(&result, buf, 3);
    }else if( ucs4 <= 0x0010FFFF )
    {
      buf[0] = 0xF0 |  (ucs4 >> 18);
      buf[1] = 0x80 | ((ucs4 >> 12) & 0x3F);
      buf[2] = 0x80 | ((ucs4 >>  6) & 0x3F);
      buf[3] = 0x80 | ( ucs4        & 0x3F);
      SV_Buf_append_mem(&result, buf, 4);
    }else
    {
      SV_Buf_append_ch(&result,'?');
    }
  }

  /*bin_dump("out",result.getBegin(),result.getLength()); */
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}

/* ----------------------------------------------------------------------------
 * convert utf-8 into ucs4
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_utf8_ucs4(SV* sv_str)
{
  UJ_UINT8* src;
  int len;
  SV_Buf result;
  const UJ_UINT8* src_end;
  const UJ_UINT8 buf_failed[4] = { 0, 0, 0, '?' };

  if( sv_str==&PL_sv_undef )
  {
    return newSVpvn("",0);
  }
  
  src = (UJ_UINT8*)SvPV(sv_str,PL_na);
  len = sv_len(sv_str);
  src_end = src+len;
  /*fprintf(stderr,"Unicode::Japanese::(xs)utf8_ucs4\n",len); */
  /*bin_dump("in ",src,len); */
  SV_Buf_init(&result,len*4);
  
  while( src<src_end )
  {
    UJ_UINT32 ucs;
    if( *src<=0x7f )
    { /* ascii. */
      SV_Buf_append_ch4(&result,htonl(*src));
      ++src;
      continue;
    }
    if( 0xc0<=*src && *src<=0xdf )
    { /* length [2] */
      const int       utf8_len = 2;
      const UJ_UINT32 ucs_min  = 0x80;
      const UJ_UINT32 ucs_max  = 0x7ff;
      if( src+1>=src_end ||
          src[1]<0x80 || 0xbf<src[1] )
      {
        SV_Buf_append_ch4(&result,htonl(*src));
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
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        continue;
      }
      
      /* ok. */
    }else if( 0xe0<=*src && *src<=0xef )
    { /* length [3] */
      const int       utf8_len = 3;
      const UJ_UINT32 ucs_min  = 0x800;
      const UJ_UINT32 ucs_max  = 0xffff;
      if( src+2>=src_end ||
          src[1]<0x80 || 0xbf<src[1] ||
          src[2]<0x80 || 0xbf<src[2] )
      {
        SV_Buf_append_ch4(&result,htonl(*src));
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
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        continue;
      }
      
      if( ucs<0xD800 || ucs>0xDBFF )
      { /* normal char, noop */
      }else
      { /* delete surrogate pair range */
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        continue;
      }
      
      /* ok. */
    }else if( 0xf0<=*src && *src<=0xf7 )
    { /* length [4] */
      const int       utf8_len = 4;
      const UJ_UINT32 ucs_min  = 0x010000;
      const UJ_UINT32 ucs_max  = 0x10ffff;
      if( src+3>=src_end ||
          src[1]<0x80 || 0xbf<src[1] ||
          src[2]<0x80 || 0xbf<src[2] ||
          src[3]<0x80 || 0xbf<src[3] )
      {
        SV_Buf_append_ch4(&result,htonl(*src));
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
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        continue;
      }
      
      /* ok. */
    }else if( 0xf8<=*src && *src<=0xfb )
    {
      const int          utf8_len = 5;
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf && 0x80<=src[2] && src[2]<=0xbf
          && 0x80<=src[3] && src[3]<=0xbf && 0x80<=src[4] && src[4]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        ++src;
        continue;
      }
      
      /* compute code point */
      src += utf8_len;
      SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
      continue;
    }else if( 0xfc<=*src && *src<=0xfd )
    {
      const int          utf8_len = 6;
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
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
        SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
        ++src;
        continue;
      }
      
      /* compute code point */
      src += utf8_len;
      SV_Buf_append_ch4(&result, *(UJ_UINT32*)buf_failed);
      continue;
    }else
    { /* invalid */
      SV_Buf_append_ch4(&result,htonl(*src));
      ++src;
      continue;
    }

    SV_Buf_append_ch4(&result,htonl(ucs));
    /*bin_dump("now",dst_begin,dst-dst_begin); */
  }

  /*bin_dump("out",result.getBegin(),result.getLength()); */
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}

/* ----------------------------------------------------------------------------
 * End Of File.
 * ------------------------------------------------------------------------- */
