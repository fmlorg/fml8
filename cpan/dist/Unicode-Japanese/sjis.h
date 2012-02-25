
#ifndef SJIS_H__
#define SJIS_H__

/* $Id: sjis.h 4494 2002-10-29 06:23:58Z hio $ */

/* 変換ができなかったときの文字 */
#define UNDEF_SJIS     ((const unsigned char*)"\x81\xac")
#define UNDEF_SJIS_LEN 2
#define UNDEF_JIS      ((const unsigned char*)"\xa2\xf7")
#define UNDEF_JIS_LEN  2

/* sjis=>eucjp変換文字判定 */
/* 1:SJIS:C, 2:SJIS:KANA */
#define CHK_SJIS_THROUGH 0
#define CHK_SJIS_C       1
#define CHK_SJIS_KANA    2
extern const unsigned char chk_sjis[256];

#endif
