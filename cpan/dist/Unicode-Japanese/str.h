#ifndef UNICODE__JAPANESE__STR_H__
#define UNICODE__JAPANESE__STR_H__

/* $Id: str.h 4654 2006-07-03 01:33:16Z hio $ */

#ifndef UJ_UINT32
#define UJ_UINT32 unsigned int
#endif
#ifndef UJ_UINT16
#define UJ_UINT16 unsigned short
#endif
#ifndef UJ_UINT8
#define UJ_UINT8 unsigned char
#endif

/* ----------------------------------------------------------------------------
 * struct SV_Buf
 */
struct SV_Buf
{
  SV* sv;
  STRLEN alloc_len;
  UJ_UINT8* dst;
  UJ_UINT8* dst_begin;
  char tmpbuf[32];
};
typedef struct SV_Buf SV_Buf;

/* ----------------------------------------------------------------------------
 * SV_Buf(STRLEN len) */
#define SV_Buf_init(pbuf,len) \
  { \
    STRLEN alen; \
    (pbuf)->alloc_len = (len); \
    (pbuf)->sv = newSVpvn("",0); \
    alen = (len)+1; \
    SvGROW((pbuf)->sv,alen); \
    (pbuf)->dst_begin = (UJ_UINT8*)SvPV((pbuf)->sv,alen); \
    (pbuf)->dst = (pbuf)->dst_begin; \
  }

/* ----------------------------------------------------------------------------
 * STRLEN getLength(){ return dst-dst_begin; } */
#define SV_Buf_getLength(pbuf) ((pbuf)->dst-(pbuf)->dst_begin)
  
/* ----------------------------------------------------------------------------
 * void setLength(){ SvCUR_set(sv,dst-dst_begin); } */
#define SV_Buf_setLength(pbuf) SvCUR_set((pbuf)->sv,SV_Buf_getLength(pbuf))

/* ----------------------------------------------------------------------------
 * UJ_UINT8* getBegin(){ return dst_begin; } */
#define SV_Buf_getBegin(pbuf) ((pbuf)->dst_begin)

/* ----------------------------------------------------------------------------
 * SV* getSv() */
#define SV_Buf_getSv(pbuf) (*(pbuf)->dst='\0', (pbuf)->sv)

/* ----------------------------------------------------------------------------
 * inline void append_ch(UJ_UINT8 ch) */
#define SV_Buf_append_ch(pbuf,ch) \
  { \
    SV_Buf_checkbuf(pbuf,1); \
    *(pbuf)->dst++ = (ch); \
  }
/* ----------------------------------------------------------------------------
 * inline void append_ch2(UJ_UINT16 ch) */
#define SV_Buf_append_ch2(pbuf,ch) \
  { \
    const UJ_UINT16 xxtmp = (ch); \
    SV_Buf_checkbuf(pbuf,2); \
    memcpy((pbuf)->dst,&xxtmp,2); \
    (pbuf)->dst += 2; \
  } \
/* ----------------------------------------------------------------------------
 * inline void append_ch3(int ch) */
#define SV_Buf_append_ch3(pbuf,ch) \
  { \
    const int xxtmp = (ch); \
    SV_Buf_checkbuf(pbuf,4); \
    memcpy((pbuf)->dst,&xxtmp,3); \
    (pbuf)->dst += 3; \
  }
/* ----------------------------------------------------------------------------
 * inline void append_ch4(int ch) */
#define SV_Buf_append_ch4(pbuf,ch) \
  { \
    const int xxtmp = (ch); \
    SV_Buf_checkbuf(pbuf,4); \
    memcpy((pbuf)->dst,&xxtmp,4); \
    (pbuf)->dst += 4; \
  }
/* ----------------------------------------------------------------------------
 * inline void append_ch5(const UJ_UINT8* src) */
#define SV_Buf_append_ch5(pbuf,str) \
  { \
    SV_Buf_checkbuf(pbuf,5); \
    memcpy((pbuf)->dst,str,5); \
    (pbuf)->dst += 5; \
  }
/* ----------------------------------------------------------------------------
 * inline void append(const UJ_UINT8* src, int len) */
#define SV_Buf_append_mem(pbuf,str,len) \
  { \
    SV_Buf_checkbuf(pbuf,len); \
    memcpy((pbuf)->dst,str,len); \
    (pbuf)->dst += (len); \
  }

/* ----------------------------------------------------------------------------
 * inline void append_entityref(UJ_UINT32 ucs) */
#define SV_Buf_append_entityref(pbuf,ucs) \
  { \
    register int write_len = snprintf((pbuf)->tmpbuf,32,"&#%u;",ucs); \
    if( write_len!=-1 && write_len<32 ) \
    { \
      SV_Buf_append_mem(pbuf,(UJ_UINT8*)(pbuf)->tmpbuf,write_len); \
    }else \
    { \
      SV_Buf_append_ch(pbuf,'?'); \
    } \
  }

/* ----------------------------------------------------------------------------
 * void checkbuf(STRLEN len) */
#define SV_Buf_checkbuf(pbuf,len) \
  { \
    if( (STRLEN)((pbuf)->dst-(pbuf)->dst_begin)+(len)+1<(pbuf)->alloc_len ) \
    { \
    }else \
    { \
      STRLEN now_len; \
      STRLEN new_len; \
      STRLEN alen; \
      STRLEN curlen; \
      \
      SV_Buf_setLength(pbuf); \
      now_len = (pbuf)->dst-(pbuf)->dst_begin; \
      new_len = ((pbuf)->alloc_len+(len))*2; \
      alen = new_len+1; \
      SvGROW((pbuf)->sv,alen); \
      (pbuf)->alloc_len = new_len; \
       \
      (pbuf)->dst_begin = (UJ_UINT8*)SvPV((pbuf)->sv,curlen); \
      (pbuf)->dst = (pbuf)->dst_begin + now_len; \
    } \
  }


#endif
