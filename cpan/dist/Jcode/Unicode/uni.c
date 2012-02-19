/*
 * $Id: uni.c,v 2.0 2005/05/16 19:08:16 dankogai Exp $
 * (c) 1999-2003 Dan Kogai <dankogai@dan.co.jp>
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */


#include <stdio.h>
#include <string.h>

#include "uni2euc.h"
#include "euc2uni.h"

#ifndef U8
#define U8 unsigned char
#endif
#ifndef U16
#define U16 unsigned short
#endif
#ifndef U32
#define U32 unsigned long
#endif

U32 _ucs2_euc(U8 *dst, U8 *src, U32 nchar){
    U32 result = 0;
    U32 len;
    char *offset;
    for (nchar /= 2; nchar > 0; nchar--, src += 2){
	offset = uni2euc[src[0]] + src[1]*4;
	strncpy((char *)dst, offset, 4);
	len = strlen(offset);
	dst += len;
	result += len;
    }
    return result;
}

# define FB_UNI 0xFFFd
# define CHKUTEN(x) (0 <= (x) && (x) <  94*94) 

U32 _euc_ucs2(U8 *dst, U8 *src){
    U32 result = 0;
    U32 kuten;
    U16 ucs2;
    for (result = 0; *src != '\0';  src++, dst += 2, result += 2){
	if (*src <= 0x7F){       /* ASCII */
	    ucs2 = src[0];
	}else if (*src == 0x8e){ /* jisx0201 */
	    if (src[1]){
		ucs2 = j01_uni[src[1]];
		src += 1;
	    }else{
		ucs2 = FB_UNI;
	    }
	}else if (*src == 0x8f){ /* jisx0212 */
	    if (src[1] && src[2]){
		kuten  = (src[1] - 0xa1)*94 + (src[2] - 0xa1);
		ucs2 = CHKUTEN(kuten) ? j12_uni[kuten] : FB_UNI;
		src += 2;
	    }else{
		ucs2 = FB_UNI;
		if (src[1])
		    src++;
	    }
	}else{                   /* jisx0208 */
	    if (src[1]){
		kuten  = (src[0] - 0xa1)*94 + (src[1] - 0xa1);
		ucs2 = CHKUTEN(kuten) ? j08_uni[kuten] : FB_UNI;
		src += 1;
	    }else{
		ucs2 = FB_UNI;
	    }
	}
	dst[0] = ucs2/256; dst[1] = ucs2%256;
    }
    return result;
}

U32 _ucs2_utf8(U8 *dst, U8 *src, U32 nchar){
    U32 ucs2;
    U32 result = 0;
    for (nchar /= 2; nchar > 0; nchar--, src += 2) {
	ucs2 = src[0]*256 + src[1];
	if (ucs2 < 0x80){      /* 1 byte */
	    *dst++ = ucs2; 
	    result += 1;
	}else if (ucs2 < 0x800){ /* 2 bytes */
	    *dst++ = (0xC0 | (ucs2 >> 6));
	    *dst++ = (0x80 | (ucs2 & 0x3F));
	    result += 2;
	}else{                /*  3 bytes */
	    *dst++ = (0xE0 | (ucs2 >> 12));
	    *dst++ = (0x80 | ((ucs2 >> 6) & 0x3F));
	    *dst++ = (0x80 | (ucs2 & 0x3F));
	    result += 3;
	}
    }
    *dst  = '\0';
    return result;
}

U32 _utf8_ucs2(U8 *dst, U8 *src){
    U32  ucs2;
    U8 c1, c2, c3;
    U32 result = 0;
  
    for(; *src != '\0'; src++, result++){
	if (*src < 0x80) {     /* 1 byte */
	    ucs2 = *src;
	}else if (*src < 0xE0){ /* 2 bytes */
	    if (src[1]){
		c1 = *src++; c2 = *src;
		ucs2 = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
	    }else{
		ucs2 = FB_UNI;
	    }
	}else{                 /* 3 bytes */
	    if (src[1] && src[2]){
		c1 = *src++; c2 = *src++; c3 = *src;
		ucs2 = ((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6)| (c3 & 0x3F);
	    }else{
		ucs2 = FB_UNI;
		if (src[1])
		    src++;
	    }
	}
	*dst++ = (ucs2 & 0xff00) >> 8; /* 1st byte */
	*dst++ = (ucs2 & 0xff);        /* 2nd byte */;
    }
    return result * 2;
}

U32 _euc_utf8(U8 *dst, U8 *src){
    U32 result = 0;
    U32 kuten;
    U16 ucs2;
    for (result = 0; *src != '\0';  src++){
	if (*src <= 0x7F){       /* ASCII */
	    ucs2 = src[0];
	}else if (*src == 0x8e){ /* jisx0201 */
	    if (src[1]){
		ucs2 = j01_uni[src[1]];
		src += 1;
	    }else{
		ucs2 = FB_UNI;
	    }
	}else if (*src == 0x8f){ /* jisx0212 */
	    if (src[1] && src[2]){
		kuten  = (src[1] - 0xa1)*94 + (src[2] - 0xa1);
		ucs2 = CHKUTEN(kuten) ? j12_uni[kuten] : FB_UNI;
		src += 2;
	    }else{
		ucs2 = FB_UNI;
		if (src[1])
		    src++;
	    }
	}else{                   /* jisx0208 */
	    if (src[1]){
		kuten  = (src[0] - 0xa1)*94 + (src[1] - 0xa1);
		ucs2 = CHKUTEN(kuten) ? j08_uni[kuten] : FB_UNI;
		src += 1;
	    }else{
		ucs2 = FB_UNI;
	    }
	}
	if (ucs2 < 0x80){      /* 1 byte */
	    *dst++ = ucs2; 
	    result += 1;
	}else if (ucs2 < 0x800){ /* 2 bytes */
	    *dst++ = (0xC0 | (ucs2 >> 6));
	    *dst++ = (0x80 | (ucs2 & 0x3F));
	    result += 2;
	}else{                /*  3 bytes */
	    *dst++ = (0xE0 | (ucs2 >> 12));
	    *dst++ = (0x80 | ((ucs2 >> 6) & 0x3F));
	    *dst++ = (0x80 | (ucs2 & 0x3F));
	    result += 3;
	}
    }
    *dst  = '\0';
    return result;
}

U32 _utf8_euc(U8 *dst, U8 *src){
    U32 result = 0;
    U32 len;
    U16 ucs2;
    U8 c1, c2, c3;
    char *offset;
    for(; *src != '\0'; src++){
	if (*src < 0x80) {     /* 1 byte */
	    ucs2 = *src;
	}else if (*src < 0xE0){ /* 2 bytes */
	    if (src[1]){
		c1 = *src++; c2 = *src;
		ucs2 = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
	    }else{
		ucs2 = FB_UNI;
	    }
	}else{                 /* 3 bytes */
	    if (src[1] && src[2]){
		c1 = *src++; c2 = *src++; c3 = *src;
		ucs2 = ((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6)| (c3 & 0x3F);
	    }else{
		ucs2 = FB_UNI;
		if (src[1]){
		    src++;
		}
	    }
	}
	offset = uni2euc[ucs2/256] + (ucs2%256)*4;
	strncpy((char *)dst, offset, 4);
	len = strlen(offset);
	dst += len;
	result += len;
    }
    return result;
}

#ifndef PERL_XS

#include <sys/errno.h>

int main(int argc, char **argv){
    U8 buf1[1024], buf2[1024];
    int result;
    
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
	result = _euc_utf8(buf1, buf2);
	fputs(buf1, stdout);
    }
    
#else
    
    while(fgets(buf1, 256, IN)){
	result = _utf8_euc(buf2, buf1);
	fputs(buf2, stdout);
    }
    
#endif

}

#endif
