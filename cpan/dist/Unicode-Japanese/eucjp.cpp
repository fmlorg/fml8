
#include "Japanese.h"
#include "sjis.h"

#ifdef TEST
#define DISP_E2S 0
#define DISP_S2E 0
#endif

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// sjis=>eucjp�Ѵ�
EXTERN_C
SV*
xs_sjis_eucjp(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);

  //fprintf(stderr,"Unicode::Japanese::(xs)sjis_eucjp\n",len);
  //bin_dump("in ",src,len);

  SV_Buf result(len);
  const unsigned char* src_end = src+len;

  while( src<src_end )
  {
    switch(chk_sjis[*src])
    {
    case CHK_SJIS_THROUGH:
      {
	const unsigned char* start = src;
	while( ++src<src_end && chk_sjis[*src]==CHK_SJIS_THROUGH );
	result.append(start,src-start);
	continue;
      }
    case CHK_SJIS_C:
      {
	if( src+2-1<src_end && 0x40<=src[1] && src[1]<=0xfc && src[1]!=0x7f )
	{
	  unsigned char tmp[2];
	  if( 0x9f <= src[1] )
	  {
	    tmp[0] = src[0]*2 - (src[0]>=0xe0 ? 0xe0 : 0x60);
	    tmp[1] = src[1] + 2;
	  }else
	  {
	    tmp[0] = src[0]*2 - (src[0]>=0xe0 ? 0xe1 : 0x61);
	    tmp[1] = src[1] + 0x60 + (src[1] < 0x7f);
	  }
	  result.append(tmp,2);
	  src += 2;
	  continue;
	}
	break;
      }
    case CHK_SJIS_KANA:
      {
	unsigned char tmp[2] = { 0x8e, src[0], };
	result.append(tmp,2);
	++src;
	continue;
      }
    default:
      {
#ifdef TEST
	fprintf(stderr,"xs_sjis_eucjp, unknown check-code[%02x] on char-code[%05x]\n",chk_sjis[*src],*src);
#endif
	result.append(*src++);
      }
    } //switch

    // invalid char
    result.append(*src++);

  } //while

  //bin_dump("out",result.getBegin(),result.getLength());
  result.setLength();

  return result.getSv();
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// eucjp=>sjis�Ѵ�ʸ��Ƚ��
// 1:EUCJP:0212, 3:EUCJP:C 4:EUCJP:KANA
#define CHK_EUCJP_THROUGH 0
#define CHK_EUCJP_0212    1
#define CHK_EUCJP_C       3
#define CHK_EUCJP_KANA    4
static const unsigned char chk_eucjp[256] =
{
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 1
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 2
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 3
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 4
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 5
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 6
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 7
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  4,  1, // 8
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 9
     0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, // a
     3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, // b
     3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, // c
     3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, // d
     3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, // e
     3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0, // f
};

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// eucjp=>sjis�Ѵ�
EXTERN_C
SV*
xs_eucjp_sjis(SV* sv_str)
{
  if( sv_str==&PL_sv_undef )
  {
    return newSVsv(&PL_sv_undef);
  }
  unsigned char* src = (unsigned char*)SvPV(sv_str,PL_na);
  int len = sv_len(sv_str);

#if DISP_E2S
  fprintf(stderr,"Unicode::Japanese::(xs)eucjp_sjis\n",len);
  bin_dump("in ",src,len);
#endif

  SV_Buf result(len);
  const unsigned char* src_end = src+len;

  while( src<src_end )
  {
    switch(chk_eucjp[*src])
    {
    case CHK_EUCJP_THROUGH:
      {
	const unsigned char* start = src;
	while( ++src<src_end && chk_eucjp[*src]==CHK_EUCJP_THROUGH );
	result.append(start,src-start);
	continue;
      }
    case CHK_EUCJP_0212:
      {
	if( src+3-1<src_end )
	{
	  result.append(UNDEF_SJIS,UNDEF_SJIS_LEN);
	  src += 3;
	  continue;
	}
	break;
      }
    case CHK_EUCJP_C:
      {
	if( src+2-1<src_end && 0xa1<=src[1] && src[1]<=0xfe )
	{
	  unsigned char tmp[2];
	  if( src[0]%2 )
	  {
	    tmp[0] = (src[0]>>1) + (src[0] < 0xdf ? 0x31 : 0x71);
	    tmp[1] = src[1] - ( 0x60 + (src[1] < 0xe0) );
	  }else
	  {
	    tmp[0] = (src[0]>>1) + (src[0] < 0xdf ? 0x30 : 0x70);
	    tmp[1] = src[1] - 2;
	  }
	  result.append(tmp,2);
	  src += 2;
	  continue;
	}
	break;
      }
    case CHK_EUCJP_KANA:
      {
	if( src+2-1<src_end && 0xa1<=src[1] && src[1]<=0xdf )
	{
	  result.append(src[1]);
	  src += 2;
	  continue;
	}
	break;
      }
    default:
      {
#ifdef TEST
	fprintf(stderr,"xs_eucjp_sjis, unknown check-code[%02x] on char-code[%05x]\n",chk_sjis[*src],*src);
#endif
      }
    } //switch

    // invalid char
    result.append(*src++);

  } //while

#if DISP_E2S
  bin_dump("out",result.getBegin(),result.getLength());
#endif

  result.setLength();

  return result.getSv();
}
