/*
 * $Id: uni.c,v 0.79 2002/01/16 02:18:49 dankogai Exp $
 * (c) 1999 Dan Kogai <dankogai@dan.co.jp>
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
/* 
isascii() is no longer used to keep compatible w/ jperl
 -- thanks, Hirofumi.Watanabe@jp.sony.com
#include <ctype.h> 
*/
#define IS_ASCII(c) ((unsigned)(c) <= 0x7F)

#include "table.h"
#include <sys/errno.h>

#define not_iso646_jp(x) ((x) != '\\' && (x) != '~')

Octet *q2o(Quad q){
  static Octet buf[8];
  Octet *bufp;
  buf[8] = '\0';
  for(bufp = &(buf[7]); q != 0; q >>= 8, bufp--){
    *bufp = q % 256;
  }
  return ++bufp;
}

Quad o2q(Octet *o, int nchar){
  Quad result = 0;
  do{
    result <<= 8;
    result += *o++;
  }while(--nchar > 0);
  return result;
}

/*--  UCS2 -> EUC --*/

int u_match(const void *key, const void *member){
  Quad x = *((Quad *)key);
  Quad y = ((Table_t *)member)->ucs2;
  int result = (x > y) ? 1 : (x < y) ? -1 : 0;
  return result;
}

Octet *u2e(Quad *qp, int pedantic){
  Table_t *t;
  static Octet buf[4];
  if (IS_ASCII(*qp)){
    if (!pedantic || not_iso646_jp(*qp)){
      return q2o(*qp);
    }
  }
  t = (Table_t *)bsearch(qp, U2E, TABLE_SIZE, sizeof(Table_t), u_match);
  if (t != NULL){
    return q2o(t->euc);
  }else{
    return (unsigned char *)"\xa2\xae"; /* во */
  }
}

size_t _ucs2_euc(Octet *dst, Octet *src, int nchar, int pedantic){
  Quad   q;
  Octet  ebuf[8];
  Octet  *o_dst = dst;
  size_t result = 0;

  for (nchar /= 2; nchar > 0; nchar--, src += 2)
    {
      q = o2q(src, 2);
      strcpy((char *)ebuf, (char *)u2e(&q, pedantic));
      strcpy((char *)dst, (char *)ebuf);
      dst += strlen((char *)ebuf);
      result += strlen((char *)ebuf);
    }
  return result;
}

/*--  EUC -> UCS2 --*/

int e_cmp(const void *a, const void *b){
  Quad x = ((Table_t *)a)->euc;
  Quad y = ((Table_t *)b)->euc;
  int result = (x > y) ? 1 : (x < y) ? -1 : 0;
  return result;
}

int e_match(const void *key, const void *member){
  Quad x = *((Quad *)key);
  Quad y = ((Table_t *)member)->euc;
  int result = (x > y) ? 1 : (x < y) ? -1 : 0;
  return result;
}

Octet *e2u(Quad *qp, int pedantic){
  Table_t *t;
  static Octet buf[4];
  if (IS_ASCII(*qp)){
    if (!pedantic || not_iso646_jp(*qp)){
      sprintf((char *)buf, "%c%c", '\0', *qp);
      return buf;
    }
  }
  t = (Table_t *)bsearch(qp, E2U, TABLE_SIZE, sizeof(Table_t), e_match);
  if (t != NULL){
      sprintf((char *)buf, "%c%c", 
	      ((t->ucs2 & 0xff00) >> 8), (t->ucs2 & 0xff));
      return buf;
  }else{
    return (unsigned char *)"\x30\x13"; /* во */
  }
}

static int INITED = 0;

void init(void){
  int i;
  if (!INITED){
    memcpy(E2U, U2E, sizeof(U2E));
    qsort(E2U, TABLE_SIZE, sizeof(Table_t), e_cmp);
    INITED = 1;
  }
}

size_t _euc_ucs2(Octet *dst, Octet *src, int pedantic){
  Quad  q;
  size_t  nchar;
  
  init();

  for (nchar = 0; 
       *src != '\0'; 
       src++, dst += 2, nchar++)
    {
      if (IS_ASCII(*src)){
	q = o2q(src, 1);
      }
      else if(*src != 0x8f){
	q = o2q(src, 2); src += 1;
      }else{
	q = o2q(src, 3); src += 2;
      }
      memcpy(dst, e2u(&q, pedantic), 2);
    }
  return nchar * 2;
}

/*--  UCS2 -> UTF8 --*/

size_t _ucs2_utf8(Octet *dst, Octet *src, int nchar){
  Quad   ucs2;
  Octet  ebuf[8];
  Octet  *o_dst = dst;
  size_t result = 0;

  for (nchar /= 2; nchar > 0; nchar--, src += 2)
    {
      ucs2 = o2q(src, 2);
      if (ucs2 < 0x80){      /* 1 byte */
	sprintf((char *)ebuf, "%c", ucs2);
      }
      else if(ucs2 < 0x800){ /* 2 bytes */
	sprintf((char *)ebuf, "%c%c", 
		(0xC0 | (ucs2 >> 6)), 
		(0x80 | (ucs2 & 0x3F))
		);
      }else{                /*  3 bytes */
	sprintf((char *)ebuf, "%c%c%c",
		(0xE0 | (ucs2 >> 12)),
                (0x80 | ((ucs2 >> 6) & 0x3F)),
		(0x80 | (ucs2 & 0x3F))
		);
      }
      strcpy((char *)dst, (char *)ebuf);
      dst += strlen((char *)ebuf);
      result += strlen((char *)ebuf);
    }
  return result;
}

/*--  UTF8 -> UCS2 --*/

size_t _utf8_ucs2(Octet *dst, Octet *src){
  Quad  ucs2;
  Octet c1, c2, c3;
  size_t  nchar = 0;

  for(; *src != '\0'; src++, nchar++){
    if (*src < 0x80) {     /* 1 byte */
      ucs2 = *src;
    }
    else if (*src < 0xE0){ /* 2 bytes */
      c1 = *src++; c2 = *src;
      ucs2 = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
    }else{                 /* 3 bytes */
      c1 = *src++; c2 = *src++; c3 = *src;
      ucs2 = ((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6)| (c3 & 0x3F);
    }
    *dst++ = (ucs2 & 0xff00) >> 8; /* 1st byte */
    *dst++ = (ucs2 & 0xff);        /* 2nd byte */;
  }
  return nchar * 2;
}

#ifndef PERL_XS

int main(int argc, char **argv){
  Octet buf1[1024], buf2[1024];
  int nchar;

  FILE *IN;
  if (argc > 1){
    IN = fopen(argv[1], "r");
    if (IN == NULL){
      fprintf(stderr, "Can't open %s; %s\n", argv[1], strerror(errno));
      exit(-1);
    }
  }else{
    IN = stdin;
  }

#ifdef EUC_UTF8

  while(fgets(buf2, 256, IN)){
    nchar = _euc_ucs2(buf1, buf2, 0);
    nchar = _ucs2_utf8(buf2, buf1, nchar);
    fputs(buf2, stdout);
  }

#else

  while(fgets(buf1, 256, IN)){
    nchar = _utf8_ucs2(buf2, buf1);
    nchar = _ucs2_euc(buf1, buf2, nchar, 0);
    fputs(buf1, stdout);
  }

#endif

}

#endif
