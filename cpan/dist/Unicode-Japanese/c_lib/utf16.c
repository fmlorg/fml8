/* ----------------------------------------------------------------------------
 * utf16.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "unijp.h"
#include "unijp_build.h"

#include "xs_compat.h"
#define g_s2u_table ((const uj_uint8*)_uj_table_s2u)
#define g_u2s_table ((const uj_uint8*)_uj_table_u2s)
#define char_null     _uj_xs_char_null
#define char_unknown  _uj_xs_char_unknown

#define xs_utf16_utf8(decl) _uj_xs_utf16_utf8(const uj_conv_t* sv_str, uj_conv_t* __out)
#define xs_utf8_utf16(decl) _uj_xs_utf8_utf16(const uj_conv_t* sv_str, uj_conv_t* __out)

#include <stdlib.h>
#include <netinet/in.h>
#define Perl_croak(msg) abort()
#include "../utf16.c"

#undef xs_utf16_utf8
#undef xs_utf8_utf16
#define xs_utf16_utf8(in,out) _uj_xs_utf16_utf8(in,out)
#define xs_utf8_utf16(in,out) _uj_xs_utf8_utf16(in,out)

uj_conv_t* _uj_utf16_to_utf8(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_utf16_utf8(in, out);
  /* ret == out|NULL */
  return ret;
}

uj_conv_t* _uj_utf8_to_utf16(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_utf8_utf16(in, out);
  /* ret == out|NULL */
  return ret;
}

/* ----------------------------------------------------------------------------
: uj_to_utf16(uj, &len).
+--------------------------------------------------------------------------- */
uj_uint8* uj_to_utf16(const unijp_t* uj, uj_size_t* p_len)
{
  uj_conv_t in;
  uj_conv_t out;
  uj_conv_t* conv_ret;
  uj_uint8* ret_buf;

  _uj_conv_set_const(&in, uj->alloc, uj->data, uj->data_len);
  conv_ret = _uj_utf8_to_utf16(&in, &out);
  if( conv_ret!=NULL )
  {
    _uj_conv_own_string(conv_ret);
    ret_buf = conv_ret->buf;
    if( p_len )
    {
      *p_len = conv_ret->buf_len;
    }
  }else
  {
    ret_buf = NULL;
  }
  return ret_buf;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
