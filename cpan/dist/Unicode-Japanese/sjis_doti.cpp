
/* $Id: sjis_doti.cpp,v 1.15 2002/07/08 07:50:28 hio Exp $ */

#include <stdio.h>
#include "Japanese.h"

EXTERN_C
SV*
xs_sjis_doti_utf8(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);

  //fprintf(stderr,"Unicode::Japanese::(xs)sjis_doti_utf8\n",len);
  //bin_dump("in ",src,len);

  SV_Buf result(len*3/2+4);
  const unsigned char* src_end = src+len;

  while( src<src_end )
  {
    const unsigned char* ptr;
    if( src[0]<0x80 )
    { // ASCII
      //fprintf(stderr,"ascii: %02x\n",src[0]);
      if( src[0]=='&' && src+3<src_end && src[1]=='#' )
      { // "&#ooooo;"のチェック
	int num = 0;
	unsigned char* ptr = src+2;
	const unsigned char* ptr_end = ptr+8<src_end ? ptr+8 : src_end;
	for( ; ptr<ptr_end; ++ptr )
	{
	  if( *ptr==';' ) break;
	  if( *ptr<'0' || '9'<*ptr ) break;
	  num = num*10 + *ptr-'0';
	}
	if( ptr<ptr_end && *ptr==';' && 0xf000<=num && num<=0xf4ff )
	{ // &#oooo;表記のdot-i絵文字
	  const unsigned char* emoji = (unsigned char*)&g_ed2u_table[num-0xf000];
	  if( emoji[3] )
	  {
	    //fprintf(stderr,"utf8-len: [%d]\n",4);
	    result.append(emoji,4);
	    src = ptr+1;
	    continue;
	  }
	}
      }
	
      result.append(*src++);
      continue;
    }else if( 0xa1<=src[0] && src[0]<=0xdf )
    { // 半角カナ
      //fprintf(stderr,"kana": %02x\n",src[0]);
      ptr = (unsigned char*)&g_s2u_table[src[0]];
      ++src;
    }else if( src+1<src_end && ( 0xf0<=src[0] && src[0]<=0xf4 ) )
    { // dot-i絵文字
      ptr = (unsigned char*)&g_ed2u_table[((src[0]&0x07)<<8)|src[1]];
      if( *(unsigned long*)ptr==0 )
      {
	register const unsigned short sjis = ntohs(*(unsigned short*)src);
	//fprintf(stderr,"sjis: %04x\n",sjis);
	ptr = (unsigned char*)&g_s2u_table[sjis];
      }
      src += 2;
    }else if( ((0x81<=src[0] && src[0]<=0x9f) || (0xe0<=src[0] && src[0]<=0xfc) )
	      && src+1<src_end
	      && (0x40<=src[1] && src[1]<=0xfc && src[1]!=0x7f) )
    { // 2バイト文字
      register const unsigned short sjis = ntohs(*(unsigned short*)src);
      //fprintf(stderr,"sjis: %04x\n",sjis);
      ptr = (unsigned char*)&g_s2u_table[sjis];
      src += 2;
    }else
    { // 不明
      //fprintf(stderr,"unknown: %02x\n",src[0]);
      result.append('?');
      ++src;
      continue;
    }

    //fprintf(stderr,"utf8-char : %02x %02x %02x %02x\n",ptr[0],ptr[1],ptr[2],ptr[3]);
    if( ptr[3] )
    {
      //fprintf(stderr,"utf8-len: [%d]\n",4);
      result.append_ch4(*(int*)ptr);
    }else if( ptr[2] )
    {
      //fprintf(stderr,"utf8-len: [%d]\n",3);
      result.append_ch3(*(int*)ptr);
    }else if( ptr[1] )
    {
      //fprintf(stderr,"utf8-len: [%d]\n",2);
      result.append_ch2(*(short*)ptr);
    }else
    {
      //fprintf(stderr,"utf8-len: [%d]\n",1);
      result.append(*ptr);
    }
  }
  //bin_dump("out",result.getBegin(),result.getLength());
  result.setLength();

  return result.getSv();
}

EXTERN_C
SV*
xs_utf8_sjis_doti(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);

  //fprintf(stderr,"Unicode::Japanese::(xs)utf8_sjis_doti\n");
  //ON_U2S( bin_dump("in ",src,len) );

  SV_Buf result(len+4);
  const unsigned char* src_end = src+len;

  while( src<src_end )
  {
    if( *src<=0x7f )
    {
      // ASCIIはまとめて追加〜
      int len = 1;
      while( src+len<src_end && src[len]<=0x7f )
      {
	++len;
      }
      result.append(src,len);
      src+=len;
      continue;
    }
    // utf8をucsに変換
    // utf8の１文字の長さチェック
    int utf8_len;
    if( 0xc0<=*src && *src<=0xdf )
    {
      utf8_len = 2;
    }else if( 0xe0<=*src && *src<=0xef )
    {
      utf8_len = 3;
    }else if( 0xf0<=*src && *src<=0xf7 )
    {
      utf8_len = 4;
    }else if( 0xf8<=*src && *src<=0xfb )
    {
      utf8_len = 5;
    }else if( 0xfc<=*src && *src<=0xfd )
    {
      utf8_len = 6;
    }else
    {
      result.append('?');
      ++src;
      continue;
    }
    // 長さ足りてるかチェック
    if( src+utf8_len-1>=src_end )
    {
      //ECHO_U2S((stderr,"  no enough buffer, here is %d, need %d\n",src_end-src,utf8_len));
      result.append('?');
      ++src;
      continue;
    }
    // ２バイト目以降が正しい文字範囲か確認
    bool succ = true;
    for( int i=1; i<utf8_len; ++i )
    {
      if( src[i]<0x80 || 0xbf<src[i] )
      {
	//ECHO_U2S((stderr,"  at %d, char out of range\n",i));
	succ = false;
	break;
      }
    }
    if( !succ )
    {
      result.append('?');
      ++src;
      continue;
    }
    // utf8からucsのコードを算出
    //ECHO_U2S((stderr,"utf8-charlen: [%d]\n",utf8_len));
    unsigned int ucs;
    switch(utf8_len)
    {
    case 2:
      {
	ucs = ((src[0] & 0x1F)<<6)|(src[1] & 0x3F);
	break;
      }
    case 3:
      {
	ucs = ((src[0] & 0x0F)<<12)|((src[1] & 0x3F)<<6)|(src[2] & 0x3F);
	break;
      }
    case 4:
      {
	ucs = ((src[0] & 0x07)<<18)|((src[1] & 0x3F)<<12)|
	  ((src[2] & 0x3f) << 6)|(src[3] & 0x3F);
	break;
      }
    case 5:
      {
	ucs = ((src[0] & 0x03) << 24)|((src[1] & 0x3F) << 18)|
	    ((src[2] & 0x3f) << 12)|((src[3] & 0x3f) << 6)|
	    (src[4] & 0x3F);
	break;
      }
    case 6:
      {
	ucs = ((src[0] & 0x03) << 30)|((src[1] & 0x3F) << 24)|
	    ((src[2] & 0x3f) << 18)|((src[3] & 0x3f) << 12)|
	    ((src[4] & 0x3f) << 6)|(src[5] & 0x3F);
	break;
      }
    default:
      {
        // NOT REACH HERE
	//ECHO_U2S((stderr,"invalid utf8-length: %d\n",utf8_len));
	ucs = '?';
      }
    }

    if( 0x0f0000<=ucs && ucs<=0x0fffff )
    { // 私用領域
      assert(utf8_len>=4);
      if( ucs<0x0ff000 )
      { // 知らない使用領域
	result.append('?');
	src += utf8_len;
	continue;
      }
      // 絵文字判定(dot-i)
      const unsigned char* const sjis = (unsigned char*)&g_eu2d_table[ucs - 0x0ff000];
      if( sjis[1]!=0 )
      { // ２バイト文字に.
	result.append_ch2(*reinterpret_cast<const unsigned short*>(sjis));
      }else if( sjis[0]!=0 )
      { // １バイト文字に.
	result.append(*sjis);
      }else
      { // マッピングなし
	result.append('?');
      }
      src += utf8_len;
      continue;
    }
    
    if( ucs & ~0xFFFF )
    { // ucs2の範囲外 (ucs4の範囲)
      result.append('?');
      src += utf8_len;
      continue;
    }
    
    // ucs => sjis
    //ECHO_U2S((stderr,"ucs2 [%04x]\n",ucs));
    const unsigned short sjis = g_u2s_table[ucs];
    //ECHO_U2S((stderr,"sjis [%04x]\n",ntohs(sjis) ));
    
    if( sjis || !ucs )
    { // 対応文字がある時とucs=='\0'の時
      if( sjis & 0xff00 )
      {
	result.append_ch2(sjis);
      }else
      {
	result.append((unsigned char)sjis);
      }
    }else if( ucs<=0x7F )
    {
      result.append((unsigned char)ucs);
    }else
    {
      result.append('?');
    }
    src += utf8_len;
    //bin_dump("now",dst_begin,dst-dst_begin);
  } /* for */

  //ON_U2S( bin_dump("out",result.getBegin(),result.getLength()) );
  result.setLength();

  return result.getSv();
}
