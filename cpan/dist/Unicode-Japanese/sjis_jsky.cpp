
// $Id: sjis_jsky.cpp,v 1.18 2002/07/04 04:52:29 hio Exp $

#include <stdio.h>
#include "Japanese.h"

#define ECHO_EJ2U(arg) //fprintf arg
#define ON_EJ2U(cmd) //cmd
#define ECHO_U2EJ(arg) //fprintf arg
#define ON_U2EJ(cmd) //cmd

EXTERN_C
SV*
xs_sjis_jsky_utf8(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  const unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);

  ECHO_EJ2U((stderr,"Unicode::Japanese::(xs)sjis_jsky_utf8\n",len));
  ON_EJ2U( bin_dump("in ",src,len) );

  SV_Buf result(len*3/2+4);
  const unsigned char* src_end = src+len;

  while( src<src_end )
  {
    const unsigned char* ptr;
    if( src[0]<0x80 )
    { // ASCII
      //fprintf(stderr,"ascii: %02x\n",src[0]);
      if( src[0]!='\e' || src+2>=src_end || src[1]!='$' )
      { // 絵文字じゃない
	result.append(*src++);
	continue;
      }
      //fprint(stderr,"detect j-sky emoji-start escape\n");
      // E_JSKY_1
      if( src[2]!='E' && src[2]!='F' && src[2]!='G' )
      {
	//fprintf(stderr,"first char is invalid");
	result.append(*src++);
	continue;
      }

      const unsigned char* begin = src;
      src += 3;
      // E_JSKY_2
      while( src+1<src_end )
      {
	if( '!'<=src[0] && src[0]<='z' )
	{
	  ++src;
	  continue;
	}
	break;
      }
      if( src[0]!=0x0f )
      {
	//fprintf(stderr,"invalid\n");
	src = begin;
	result.append(*src++);
	continue;
      }
      ++src;
      const int j1 = (begin[2]-'E')<<8;
      for( const unsigned char* ptr = begin+3; ptr<src-1; ++ptr )
      {
	//fprintf(stderr," <%c%c:%04x>\n",begin[2],*ptr,j1+*ptr);
	//fprintf(stderr,"   => %04x\n",g_ej2u_table[j1+*ptr]);
	const unsigned char* str = (unsigned char*)&g_ej2u_table[j1+*ptr];
	//fprintf(stderr,"   len: %d\n",str[3]?4:strlen((char*)str));
	result.append(str,str[3]?4:strlen((char*)str));
      }
      //fprintf(stderr,"j-sky string done.\n");
      continue;
    }else if( 0xa1<=src[0] && src[0]<=0xdf )
    { // 半角カナ
      //fprintf(stderr,"kana": %02x\n",src[0]);
      ptr = (unsigned char*)&g_s2u_table[src[0]];
      ++src;
    }else if( ((0x81<=src[0] && src[0]<=0x9f) || (0xe0<=src[0] && src[0]<=0xfc) )
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
  ON_EJ2U( bin_dump("out",result.getBegin(),result.getLength()) );
  result.setLength();

  return result.getSv();
}


EXTERN_C
SV*
xs_utf8_sjis_jsky(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);

  ECHO_U2EJ((stderr,"Unicode::Japanese::(xs)utf8_sjis\n"));
  ON_U2EJ( bin_dump("in ",src,len) );

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
      ECHO_U2EJ((stderr,"  no enough buffer, here is %d, need %d\n",src_end-src,utf8_len));
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
	ECHO_U2EJ((stderr,"  at %d, char out of range\n",i));
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
    ECHO_U2EJ((stderr,"utf8-charlen: [%d]\n",utf8_len));
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
	ECHO_U2EJ((stderr,"invalid utf8-length: %d\n",utf8_len));
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
      // 絵文字判定(j-sky)
      const unsigned char* const sjis = &g_eu2j_table[(ucs - 0x0ff000)*5];
      //fprintf(stderr,"  emoji: %02x %02x %02x %02x %02x\n",
      //	  sjis[0],sjis[1],sjis[2],sjis[3],sjis[4]);
      if( sjis[4]!=0 )
      { // ５バイト文字に.
	result.append_ch5(sjis);
      }else if( sjis[3]!=0 )
      { // ４バイト文字に.
	assert("not reach here" && 0);
	result.append_ch4(*reinterpret_cast<const int*>(sjis));
      }else if( sjis[2]!=0 )
      { // ３バイト文字に.
	assert("not reach here" && 0);
	result.append_ch3(*reinterpret_cast<const int*>(sjis));
      }else if( sjis[1]!=0 )
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
    ECHO_U2EJ((stderr,"ucs2 [%04x]\n",ucs));
    const unsigned short sjis = g_u2s_table[ucs];
    ECHO_U2EJ((stderr,"sjis [%04x]\n",ntohs(sjis) ));
    
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

  ON_U2EJ( bin_dump("out",result.getBegin(),result.getLength()) );
  result.setLength();
  sv_2mortal(result.getSv());

  // packing J-SKY emoji escapes
  SV_Buf pack(result.getLength());
  src = result.getBegin();
  src_end = src + result.getLength();
  unsigned char* ptr = src;
  for( ; src+5*2-1<src_end; ++src )
  {
    // E_JSKY_START  "\e\$",
    if( src[0]!='\x1b' ) continue;
    if( src[1]!='$' ) continue;
    // E_JSKY1   '[EFG]',
    //fprintf(stderr,"  found emoji-start\n");
    if( src[2]!='E' && src[2]!='F' && src[2]!='G' )
    {
      //fprintf(stderr,"  invalid ch1 [%x:%02x]\n",src[2],src[2]);
      continue;
    }
    unsigned char ch1 = src[2];
    // E_JSKY2    '[\!-\;\=-z\xbc]',
    if( src[3]<'!' || 'z'<src[3] )
    {
      //fprintf(stderr,"  invalid ch2 [%02x]\n",src[3]);
      continue;
    }
    // E_JSKY_END    "\x0f",
    if( src[4]!='\x0f' ) continue;

    //fprintf(stderr,"  found first emoji [%02x:%c]\n",ch1,ch1);
    src += 5;
    pack.append(ptr,(src-1)-ptr);
    unsigned char tmpl[5] = { '\x1b','$',0,0,'\x0f',};
    tmpl[2] = ch1;
    for( ; src_end-src>=5; src+= 5 )
    {
      tmpl[3] = src[3];
      if( memcmp(src,tmpl,5)!=0 ) break;
      //fprintf(stderr,"  packing...[%02x]\n",src[3]);
      pack.append(src[3]);
    }
    //fprintf(stderr,"  pack done.\n");
    pack.append('\x0f');
    ptr = src;
  }
  //fprintf(stderr,"  pack complete.\n");
  //fprintf(stderr,"  append len %0d\n",src_end-ptr);
  if( ptr!=src_end )
  {
    pack.append(ptr,src_end-ptr);
  }

  ON_U2EJ( bin_dump("out",pack.getBegin(),pack.getLength()) );
  pack.setLength();

  return pack.getSv();
}
