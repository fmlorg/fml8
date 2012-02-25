/* ----------------------------------------------------------------------------
 * ucs4.c
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

#define xs_ucs4_utf8(decl) _uj_xs_ucs4_utf8(const uj_conv_t* sv_str, uj_conv_t* __out)
#define xs_utf8_ucs4(decl) _uj_xs_utf8_ucs4(const uj_conv_t* sv_str, uj_conv_t* __out)

#include <stdlib.h>
#include <netinet/in.h>
#define Perl_croak(msg) abort()

#include "../ucs4.c"

#undef xs_ucs4_utf8
#undef xs_utf8_ucs4
#define xs_ucs4_utf8(in,out) _uj_xs_ucs4_utf8(in,out)
#define xs_utf8_ucs4(in,out) _uj_xs_utf8_ucs4(in,out)

uj_conv_t* _uj_ucs4_to_utf8(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_ucs4_utf8(in, out);
  /* ret == out|NULL */
  return ret;
}

uj_conv_t* _uj_utf8_to_ucs4(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_utf8_ucs4(in, out);
  /* ret == out|NULL */
  return ret;
}

/* ----------------------------------------------------------------------------
: uj_to_ucs4(uj, &len).
+--------------------------------------------------------------------------- */
uj_uint8* uj_to_ucs4(const unijp_t* uj, uj_size_t* p_len)
{
  uj_conv_t in;
  uj_conv_t out;
  uj_conv_t* conv_ret;
  uj_uint8* ret_buf;

  _uj_conv_set_const(&in, uj->alloc, uj->data, uj->data_len);
  conv_ret = _uj_utf8_to_ucs4(&in, &out);
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
