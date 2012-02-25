/* ----------------------------------------------------------------------------
 * unijp_build.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_BUILD_H
#define UNIJP_BUILD_H

#ifdef __cplusplus
extern "C"
{
#endif

#include "unijp.h"
#include "unijp_table.h"

extern void* _uj_alloc(const uj_alloc_t* alloc, uj_size_t size);
extern void* _uj_realloc(const uj_alloc_t* alloc, void* ptr, uj_size_t size);
extern void  _uj_free(const uj_alloc_t* alloc, void* ptr);

struct uj_conv_s
{
  const uj_alloc_t* alloc;
  uj_uint8* buf;       /* never becomes null. */
  uj_size_t buf_len;
  uj_size_t buf_bufsize; /* 0 means buf is contant or owned by other object. */
};
typedef struct uj_conv_s uj_conv_t;
extern void _uj_conv_set_const(uj_conv_t* conv, const uj_alloc_t* alloc, const uj_uint8* str, uj_size_t len);
extern uj_uint8* _uj_conv_own_string(uj_conv_t* conv);
extern void _uj_conv_move_owner(uj_conv_t* dst, uj_conv_t* src);
extern void _uj_conv_free_buffer(uj_conv_t* conv);

extern uj_conv_t* _uj_any_to_utf8(const uj_conv_t* in, uj_conv_t* out, uj_charcode_t icode);
extern uj_conv_t* _uj_validate_utf8(const uj_conv_t* in, uj_conv_t* out);

extern uj_conv_t* _uj_sjis_to_utf8(const uj_conv_t* in, uj_conv_t* out);
extern uj_conv_t* _uj_utf8_to_sjis(const uj_conv_t* in, uj_conv_t* out);

extern uj_conv_t* _uj_utf8_to_eucjp(const uj_conv_t* in, uj_conv_t* out);
extern uj_conv_t* _uj_eucjp_to_utf8(const uj_conv_t* in, uj_conv_t* out);

extern uj_conv_t* _uj_utf8_to_jis(const uj_conv_t* in, uj_conv_t* out);
extern uj_conv_t* _uj_jis_to_utf8(const uj_conv_t* in, uj_conv_t* out);

extern uj_conv_t* _uj_utf8_to_ucs2(const uj_conv_t* in, uj_conv_t* out);
extern uj_conv_t* _uj_ucs2_to_utf8(const uj_conv_t* in, uj_conv_t* out);

extern uj_conv_t* _uj_utf8_to_ucs4(const uj_conv_t* in, uj_conv_t* out);
extern uj_conv_t* _uj_ucs4_to_utf8(const uj_conv_t* in, uj_conv_t* out);

extern uj_conv_t* _uj_utf8_to_utf16(const uj_conv_t* in, uj_conv_t* out);
extern uj_conv_t* _uj_utf16_to_utf8(const uj_conv_t* in, uj_conv_t* out);

#ifdef __cplusplus
}
#endif

#endif /* !defined(UNIJP_BUILD_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
