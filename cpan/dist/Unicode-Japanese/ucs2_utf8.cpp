
// $Id: ucs2_utf8.cpp,v 1.5 2002/07/01 00:09:54 hio Exp $

#include "Japanese.h"

/*
 * ucs2=>utf8Ê¸»úÎóÊÑ´¹
 */
EXTERN_C
SV*
xs_ucs2_utf8(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVpvn("",0);
  }
  STRLEN PL_na;
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  const int len = sv_len(sv_str);

  //fprintf(stderr,"Unicode::Japanese::(xs)ucs2_utf8\n",len);
  //bin_dump("in ",src,len);

  SV_Buf result(len*3/2+4);

  if( len&1 )
  {
    Perl_croak(aTHX_ "Unicode::Japanese::ucs2_utf8, invalid length (not 2*n)");
  }

  const unsigned char* src_end = src+(len&~1);

  unsigned char buf[4];
  for(; src<src_end; src+=2 )
  {
    const unsigned short ucs2 = ntohs(*(unsigned short*)src);
    if( ucs2<0x80 )
    {
      buf[0] = (unsigned char)ucs2;
      result.append(buf,1);
    }else if( ucs2<0x800 )
    {
      buf[0] = 0xC0 | (ucs2 >> 6);
      buf[1] = 0x80 | (ucs2 & 0x3F);
      result.append(buf,2);
    }else
    {
      buf[0] = 0xE0 | (ucs2 >> 12);
      buf[1] = 0x80 | ((ucs2 >> 6) & 0x3F);
      buf[2] = 0x80 | (ucs2 & 0x3F);
      result.append(buf,3);
    }
  }

  //bin_dump("out",result.getBegin(),result.getLength());
  result.setLength();

  return result.getSv();
}

/*
 * utf8=>ucs2Ê¸»úÎóÊÑ´¹
 */
EXTERN_C
SV*
xs_utf8_ucs2(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVpvn("",0);
  }
  STRLEN PL_na;
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  const int len = sv_len(sv_str);

  //fprintf(stderr,"Unicode::Japanese::(xs)utf8_ucs2\n",len);
  //bin_dump("in ",src,len);

  SV_Buf result(len);

  const unsigned char* src_end = src+len;

  while( src<src_end )
  {
    if( *src<=0x7f )
    {
      result.append_ch2(htons(*src++));
      continue;
    }
    int utf8_len,ucs2;
    if( 0xc0<=*src && *src<=0xdf )
    { // length [2]
      utf8_len = 2;
      if( src+1>=src_end ||
	  src[1]<0x80 || 0xbf<src[1] )
      {
	result.append_ch2(htons(*src++));
	continue;
      }
      ucs2 = ((src[0] & 0x1F)<<6)|(src[1] & 0x3F);
    }else if( 0xe0<=*src && *src<=0xef )
    { // length [3]
      utf8_len = 3;
      if( src+2>=src_end ||
	  src[1]<0x80 || 0xbf<src[1] ||
	  src[2]<0x80 || 0xbf<src[2] )
      {
	result.append_ch2(htons(*src++));
	continue;
      }
      ucs2 = ((src[0] & 0x0F)<<12)|((src[1] & 0x3F)<<6)|(src[2] & 0x3F);
    }else if( 0xf0<=*src && *src<=0xf7 )
    { // length [4]
      utf8_len = 4;
      if( src+3>=src_end ||
	  src[1]<0x80 || 0xbf<src[1] ||
	  src[2]<0x80 || 0xbf<src[2] ||
	  src[3]<0x80 || 0xbf<src[3] )
      {
	result.append_ch2(htons(*src++));
	continue;
      }
      ucs2 = ((src[0] & 0x07)<<18)|((src[1] & 0x3F)<<12)|
	((src[2] & 0x3f) << 6)|(src[3] & 0x3F);
    }else if( 0xf8<=*src && *src<=0xfb )
    { // length [5]
      utf8_len = 5;
      if( src+4>=src_end ||
	  src[1]<0x80 || 0xbf<src[1] ||
	  src[2]<0x80 || 0xbf<src[2] ||
	  src[3]<0x80 || 0xbf<src[3] ||
	  src[4]<0x80 || 0xbf<src[4] )
      {
	result.append_ch2(htons(*src++));
	continue;
      }
    }else if( 0xfc<=*src && *src<=0xfd )
    { // length [6]
      utf8_len = 6;
      if( src+5>=src_end ||
	  src[1]<0x80 || 0xbf<src[1] ||
	  src[2]<0x80 || 0xbf<src[2] ||
	  src[3]<0x80 || 0xbf<src[3] ||
	  src[4]<0x80 || 0xbf<src[4] ||
	  src[5]<0x80 || 0xbf<src[5] )
      {
	result.append_ch2(htons(*src++));
	continue;
      }
    }else
    { // invalid
      result.append_ch2(htons(*src++));
      continue;
    }

    if( ucs2 & ~0xFFFF )
    { // ucs2¤ÎÈÏ°Ï³° (ucs4¤ÎÈÏ°Ï)
      result.append_ch2(htons('?'));
      src += utf8_len;
      continue;
    }
    result.append_ch2(htons(ucs2));
    src += utf8_len;
    //bin_dump("now",dst_begin,dst-dst_begin);
  }

  //bin_dump("out",result.getBegin(),result.getLength());
  result.setLength();

  return result.getSv();
}
