/* ----------------------------------------------------------------------------
 * utf16_utf8.c
 * ----------------------------------------------------------------------------
 * Mastering programed by YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */


#include "Japanese.h"

#define ENABLE_SURROGATE_PAIR 1

/* ----------------------------------------------------------------------------
 * convert utf-16 into utf-8
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_utf16_utf8(SV* sv_str)
{
  UJ_UINT8* src;
  STRLEN len;
  SV_Buf result;
  const UJ_UINT8* src_end;
  UJ_UINT8 buf[4];

  if( sv_str==&PL_sv_undef )
  {
    return newSVpvn("",0);
  }
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
  {
    return newSVpvn("",0);
  }
  
  src = (UJ_UINT8*)SvPV(sv_str, len);
  src_end = src+(len&~1);
  /*fprintf(stderr,"Unicode::Japanese::(xs)utf16_utf8\n",len);*/
  /*bin_dump("in ",src,len);*/
  SV_Buf_init(&result,len*3/2+4);

  if( len&1 )
  {
    Perl_croak(aTHX_ "Unicode::Japanese::utf16_utf8, invalid length (not 2*n)");
  }

  for(; src<src_end; src+=2 )
  {
    const UJ_UINT16 utf16 = (src[0]<<8)+src[1]; /* ntohs */
    if( utf16<0x80 )
    {
      SV_Buf_append_ch(&result,(UJ_UINT8)utf16);
    }else if( utf16<0x800 )
    {
      buf[0] = 0xC0 | (utf16 >> 6);
      buf[1] = 0x80 | (utf16 & 0x3F);
      SV_Buf_append_ch2(&result, *(UJ_UINT16*)buf);
    }else if( !(0xd800 <= utf16 && utf16 <= 0xdfff) )
    { /* normal char (non surrogate pair) */
      buf[0] = 0xE0 | (utf16 >> 12);
      buf[1] = 0x80 | ((utf16 >> 6) & 0x3F);
      buf[2] = 0x80 | (utf16 & 0x3F);
      SV_Buf_append_ch3(&result,*(UJ_UINT32*)buf);
    }else
    { /* surrogate pair */
      if( src+2<src_end )
      {
        const UJ_UINT16 utf16a = (src[2]<<8)+src[3]; /* ntohs */
        if( utf16<=0xdbff && 0xdc00 <= utf16a && utf16a <= 0xdfff )
        {
#if ENABLE_SURROGATE_PAIR
          const UJ_UINT32  ucs4   = ((utf16&0x03FF)<<10|(utf16a&0x03FF))+0x010000;
          src += 2;
          if( 0x010000<=ucs4 && ucs4<=0x10FFFF )
          {
            buf[0] = 0xF0 | ((ucs4>>18) & 0x3F);
            buf[1] = 0x80 | ((ucs4>>12) & 0x3F);
            buf[2] = 0x80 | ((ucs4>>6) & 0x3F);
            buf[3] = 0x80 | (ucs4 & 0x3F);
            SV_Buf_append_ch4(&result,*(UJ_UINT32*)buf);
          }else
          {
            /* utf8 not support >= U+10FFFF */
            /* or illegal representation */
            SV_Buf_append_ch(&result,'?');
          }
#else
          {
            /* surrogate pair disabled. */
            SV_Buf_append_ch(&result,'?');
          }
#endif
        }else
        {
          /* invalid surrogate */
          SV_Buf_append_ch(&result,'?');
        }
      }else
      {
        /* no trail surrogate */
        SV_Buf_append_ch(&result,'?');
      }
    }
  }

  /*bin_dump("out",result.getBegin(),result.getLength()); */
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}

/* ----------------------------------------------------------------------------
 * convert utf-8 into utf-16
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_utf8_utf16(SV* sv_str)
{
  UJ_UINT8* src;
  STRLEN len;
  SV_Buf result;
  const UJ_UINT8* src_end;

  if( sv_str==&PL_sv_undef )
  {
    return newSVpvn("",0);
  }
  if( SvGMAGICAL(sv_str) )
  {
    mg_get(sv_str);
  }
  if( !SvOK(sv_str) )
  {
    return newSVpvn("",0);
  }
  
  src = (UJ_UINT8*)SvPV(sv_str, len);
  src_end = src+len;
  /*fprintf(stderr,"Unicode::Japanese::(xs)utf8_utf16\n",len); */
  /*bin_dump("in ",src,len); */
  SV_Buf_init(&result,len*2);
  
  while( src<src_end )
  {
    UJ_UINT32 ucs;
    if( *src<=0x7f )
    {
      SV_Buf_append_ch2(&result,htons(*src));
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
        SV_Buf_append_ch2(&result,htons(*src));
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
        SV_Buf_append_ch2(&result,htons('?'));
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
        SV_Buf_append_ch2(&result,htons(*src));
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
        SV_Buf_append_ch2(&result,htons('?'));
        continue;
      }
      
      if( ucs<0xD800 || ucs>0xDBFF )
      { /* normal char, noop */
      }else
      { /* delete surrogate pair range */
        SV_Buf_append_ch2(&result,htons('?'));
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
        SV_Buf_append_ch2(&result,htons(*src));
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
        SV_Buf_append_ch2(&result,htons('?'));
        continue;
      }
      
#if ENABLE_SURROGATE_PAIR
      { /* encode surrogate pair */
        const UJ_UINT32 surrogate = ucs - 0x010000;
        SV_Buf_append_ch2(&result,htons(((surrogate>>10)&0x03FF)|0xD800));
        SV_Buf_append_ch2(&result,htons(((surrogate    )&0x03FF)|0xDC00));
        continue;
      }
#else
      { /* not supported */
        SV_Buf_append_ch2(&result,htons('?'));
        continue;
      }
#endif
      
      /* ok. */
    }else if( 0xf8<=*src && *src<=0xfb )
    {
      const int          utf8_len = 5;
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch2(&result,htons('?'));
        ++src;
        continue;
      }
      /* check follow sequences */
      if( 0x80<=src[1] && src[1]<=0xbf && 0x80<=src[2] && src[2]<=0xbf
          && 0x80<=src[3] && src[3]<=0xbf && 0x80<=src[4] && src[4]<=0xbf )
      { /* noop */
      }else
      {
        SV_Buf_append_ch2(&result,htons('?'));
        ++src;
        continue;
      }
      
      /* compute code point */
      src += utf8_len;
      SV_Buf_append_ch2(&result,htons('?'));
      continue;
    }else if( 0xfc<=*src && *src<=0xfd )
    {
      const int          utf8_len = 6;
      if( src+utf8_len<=src_end )
      { /* noop */
      }else
      { /* no enough sequence */
        SV_Buf_append_ch2(&result,htons('?'));
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
        SV_Buf_append_ch2(&result,htons('?'));
        ++src;
        continue;
      }
      
      /* compute code point */
      src += utf8_len;
      SV_Buf_append_ch2(&result,htons('?'));
      continue;
    }else
    { /* invalid */
      SV_Buf_append_ch2(&result,htons(*src));
      ++src;
      continue;
    }

    if( ucs & ~0xFFFF )
    { /* utf16及�炾炡� (ucs4及�炾�) */
      SV_Buf_append_ch2(&result,htons('?'));
      continue;
    }
    SV_Buf_append_ch2(&result,htons(ucs));
    /*bin_dump("now",dst_begin,dst-dst_begin); */
  }

  /*bin_dump("out",result.getBegin(),result.getLength()); */
  SV_Buf_setLength(&result);

  return SV_Buf_getSv(&result);
}

/* ----------------------------------------------------------------------------
 * End Of File.
 * ------------------------------------------------------------------------- */
