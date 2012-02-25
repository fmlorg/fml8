/* ----------------------------------------------------------------------------
 * unijp.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_H
#define UNIJP_H

#ifdef __cplusplus
extern "C"
{
#endif

#include "unijp_types.h"
#include "unijp_version.h"

struct unijp_s
{
  const uj_alloc_t* alloc;
  uj_uint8* data;
  uj_size_t data_len;
  uj_bool   is_binary;
};
typedef struct unijp_s unijp_t;

/* ----------------------------------------------------------------------------
: uj_new(str, bytes_len, icode).
+--------------------------------------------------------------------------- */
extern unijp_t* uj_new(const uj_uint8* str, uj_size_t bytes, uj_charcode_t icode);

/* ----------------------------------------------------------------------------
: uj_delete(uj).
+--------------------------------------------------------------------------- */
extern void uj_delete(unijp_t* uj);

/* ----------------------------------------------------------------------------
: uj_conv(uj, ocode, &len).
+--------------------------------------------------------------------------- */
extern uj_uint8* uj_conv(unijp_t* uj, uj_charcode_t ocode, uj_size_t* p_len);

/* ----------------------------------------------------------------------------
: str = uj_to_utf8(uj, &len).
: str = uj_to_sjis(uj, &len).
: str = uj_to_eucjp(uj, &len).
: str = uj_to_jis(uj, &len).
+--------------------------------------------------------------------------- */
extern uj_uint8* uj_to_utf8(const unijp_t* uj, uj_size_t* p_len);
extern uj_uint8* uj_to_sjis(const unijp_t* uj, uj_size_t* p_len);
extern uj_uint8* uj_to_eucjp(const unijp_t* uj, uj_size_t* p_len);
extern uj_uint8* uj_to_jis(const unijp_t* uj, uj_size_t* p_len);
extern uj_uint8* uj_to_ucs2(const unijp_t* uj, uj_size_t* p_len);
extern uj_uint8* uj_to_ucs4(const unijp_t* uj, uj_size_t* p_len);
extern uj_uint8* uj_to_utf16(const unijp_t* uj, uj_size_t* p_len);

/* ----------------------------------------------------------------------------
: uj_getcode(str, len).
+--------------------------------------------------------------------------- */
extern uj_charcode_t uj_getcode(const uj_uint8* str, uj_size_t len);

/* ----------------------------------------------------------------------------
: uj_charcode_parse(str).
: uj_charcode_str(code).
+--------------------------------------------------------------------------- */
extern uj_charcode_t uj_charcode_parse(const char* name);
extern uj_charcode_t uj_charcode_parse_n(const char* name, int str_len);
extern const char*   uj_charcode_str(uj_charcode_t code);

#ifdef __cplusplus
}
#endif

#endif /* !defined(UNIJP_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
