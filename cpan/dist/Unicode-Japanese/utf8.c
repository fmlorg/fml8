/* ----------------------------------------------------------------------------
 * utf16_utf8.c
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "Japanese.h"

/* ----------------------------------------------------------------------------
 * replace invalid UTF-8 chars with '?'
 * ------------------------------------------------------------------------- */
EXTERN_C
SV*
xs_validate_utf8(SV* sv_str) {
	  unsigned char* src;
	  STRLEN len;
	  SV_Buf result;
	  const unsigned char* src_end;

	  if (sv_str == &PL_sv_undef) {
		  return newSVpvn("", 0);
	  }
	  if( SvGMAGICAL(sv_str) )
	  {
	    mg_get(sv_str);
	  }
	  if( !SvOK(sv_str) )
	  {
	    return newSVpvn("", 0);
	  }
  
	  src = (unsigned char*)SvPV(sv_str, len);
	  src_end = src + len;
	  SV_Buf_init(&result, len);

	  while (src < src_end) {
		  if (*src >= 0xC0 && *src < 0xC1) {
			  /* 2 bytes char which is restricted 1 byte. */
			  if (src + 1 <= src_end) {
				  if (src[1] >= 0x80 && src[1] <= 0xBF) {
					  SV_Buf_append_ch(&result, '?');
					  src += 2;
					  continue;
				  }
			  }
		  }
		  else if (*src == 0xE0) {
			  /* 3 bytes char which is restricted <= 2 bytes. */
			  if (src + 2 <= src_end) {
				  if (src[1] >= 0x80 && src[1] <= 0x9F &&
					  src[2] >= 0x80 && src[2] <= 0xBF) {

					  SV_Buf_append_ch(&result, '?');
					  src += 3;
					  continue;
				  }
			  }
		  }
		  else if (*src == 0xF0) {
			  /* 4 bytes char which is restricted <= 3 bytes. */
			  if (src + 3 <= src_end) {
				  if (src[1] >= 0x80 && src[1] <= 0x8F &&
					  src[2] >= 0x80 && src[2] <= 0xBF &&
					  src[3] >= 0x80 && src[3] <= 0xBF) {

					  SV_Buf_append_ch(&result, '?');
					  src += 4;
					  continue;
				  }
			  }
		  }
		  else if (*src == 0xF4) {
			  /* > U+10FFFF (4byte) */
			  if (src + 3 <= src_end) {
				  if (src[1] >= 0x90 && src[1] <= 0xBF &&
					  src[2] >= 0x80 && src[2] <= 0xBF &&
					  src[3] >= 0x80 && src[3] <= 0xBF) {

					  SV_Buf_append_ch(&result, '?');
					  src += 4;
					  continue;
				  }
			  }
		  }
		  else if (*src >= 0xF5 && *src <= 0xF7) {
			  /* ditto */
			  if (src + 3 <= src_end) {
				  if (src[1] >= 0x80 && src[1] <= 0xBF &&
					  src[2] >= 0x80 && src[2] <= 0xBF &&
					  src[3] >= 0x80 && src[3] <= 0xBF) {

					  SV_Buf_append_ch(&result, '?');
					  src += 4;
					  continue;
				  }
			  }
		  }
		  else if (*src >= 0xF8 && *src <= 0xFB) {
			  /* > U+10FFFF (5byte) */
			  if (src + 4 <= src_end) {
				  if (src[1] >= 0x80 && src[1] <= 0xBF &&
					  src[2] >= 0x80 && src[2] <= 0xBF &&
					  src[3] >= 0x80 && src[3] <= 0xBF &&
					  src[4] >= 0x80 && src[4] <= 0xBF) {

					  SV_Buf_append_ch(&result, '?');
					  src += 5;
					  continue;
				  }
			  }
		  }
		  else if (*src >= 0xFC && *src <= 0xFD) {
			  /* > U+10FFFF (6byte) */
			  if (src + 5 <= src_end) {
				  if (src[1] >= 0x80 && src[1] <= 0xBF &&
					  src[2] >= 0x80 && src[2] <= 0xBF &&
					  src[3] >= 0x80 && src[3] <= 0xBF &&
					  src[4] >= 0x80 && src[4] <= 0xBF &&
					  src[5] >= 0x80 && src[5] <= 0xBF) {

					  SV_Buf_append_ch(&result, '?');
					  src += 6;
					  continue;
				  }
			  }
		  }

		  SV_Buf_append_ch(&result, *src);
		  src++;
	  }

	  SV_Buf_setLength(&result);
	  return SV_Buf_getSv(&result);
}

/* ----------------------------------------------------------------------------
 * End Of File.
 * ------------------------------------------------------------------------- */
