
#ifndef STR_H__
#define STR_H__

// $Id: str.h,v 1.7 2002/07/04 04:52:29 hio Exp $

// BUF_MALLOC : use malloc()
// (undef)    : use SV* buffer directly
//#define BUF_MALLOC

class SV_Buf
{
private:
#ifndef BUF_MALLOC
  SV* sv;
#endif
  STRLEN alloc_len;
  unsigned char* dst;
  unsigned char* dst_begin;

public:
#ifndef BUF_MALLOC
  SV_Buf(STRLEN len) : alloc_len(len)
  {
    sv = newSVpvn("",0);
    STRLEN alen = alloc_len+1;
    //fprintf(stderr,"sv = %#08x, len = %d\n",sv,alen);
    SvGROW(sv,alen);
    dst = (unsigned char*)SvPV(sv,alen);
    dst_begin = dst;
  }
#else
  SV_Buf(STRLEN len) : alloc_len(len)
  {
    dst = (unsigned char*)malloc(alloc_len+1);
    dst_begin = dst;
    fprintf(stderr,"malloc = %#08x\n",dst_begin);
  }
  ~SV_Buf()
  {
    free(dst_begin);
  }
#endif
  STRLEN getLength(){ return dst-dst_begin; }
#ifndef BUF_MALLOC
  void setLength(){ SvCUR_set(sv,dst-dst_begin); }
#else
  void setLength(){}
#endif
  unsigned char* getBegin(){ return dst_begin; }
  SV* getSv()
  {
#ifndef BUF_MALLOC
    return sv;
#else
    return newSVpvn((char*)dst_begin,dst-dst_begin);
#endif
  }
  inline void append(unsigned char ch)
  { // same as append_ch
    checkbuf(1);
    *dst++ = ch;
  }
  inline void append_ch(unsigned char ch)
  {
    checkbuf(1);
    *dst++ = ch;
  }
  inline void append_ch2(unsigned short ch)
  {
    checkbuf(2);
    *(unsigned short*)dst = ch;
    dst += 2;
  }
  inline void append_ch3(int ch)
  {
    checkbuf(4);
    *(int*)dst = ch;
    dst += 3;
  }
  inline void append_ch4(int ch)
  {
    checkbuf(4);
    *(int*)dst = ch;
    dst += 4;
  }
  inline void append_ch5(const unsigned char* src)
  {
    checkbuf(5);
    memcpy(dst,src,5);
    dst += 5;
  }
  inline void append(const unsigned char* src, int len)
  {
    checkbuf(len);
    memcpy(dst,src,len);
    dst += len;
  }
  // entity reference で追加
  inline void append_entityref(unsigned long ucs)
  {
    char buf[32];
    register int write_len = snprintf(buf,32,"&#%lu;",ucs);
    if( write_len!=-1 && write_len<32 )
    {
      append((unsigned char*)buf,write_len);
    }else
    { // 失敗するコトなんてないと思うけど….
      // -1はglibc2.0.6以前, 2.1以降は必要なサイズ
      append_ch('?');
    }
  }
  void checkbuf(STRLEN len)
  {
#ifdef TEST
    if( len==0 )
    {
      fprintf(stderr,"SV_Buf.checkbuf, check length 0.\n");
    }
#endif
    if( (dst-dst_begin)+len>=alloc_len )
    {
      STRLEN now_len = dst-dst_begin;
      STRLEN new_len = (alloc_len+len)*2;
#ifdef TEST
      fprintf(stderr,"<<SV_Buf.realloc>> %d+%d/%d => %d\n",now_len,len,alloc_len,new_len);
#endif
#ifndef BUF_MALLOC
      setLength();
      STRLEN alen = new_len+1;
      SvGROW(sv,alen);
      STRLEN curlen;
      dst_begin = (unsigned char*)SvPV(sv,curlen);
#else
      unsigned char* buf = (unsigned char*)malloc(new_len+1);
      memcpy(buf,dst_begin,now_len);
      free(dst_begin);
      dst_begin = buf;
#endif
      alloc_len = new_len;
      dst = dst_begin + now_len;
    }
  }
};

#endif


