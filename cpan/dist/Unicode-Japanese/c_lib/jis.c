/* ----------------------------------------------------------------------------
 * jis.c
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
#define chk_sjis  _uj_xs_chk_sjis

#define xs_jis_sjis(decl) _uj_xs_jis_sjis(const uj_conv_t* sv_str, uj_conv_t* __out)
#define xs_sjis_jis(decl) _uj_xs_sjis_jis(const uj_conv_t* sv_str, uj_conv_t* __out)

#include "../jis.c"
#undef xs_jis_sjis
#undef xs_sjis_jis
#define xs_jis_sjis(in,out) _uj_xs_jis_sjis(in,out)
#define xs_sjis_jis(in,out) _uj_xs_sjis_jis(in,out)

uj_conv_t* _uj_sjis_to_jis(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_sjis_jis(in, out);
  /* ret == out|NULL */
  return ret;
}

uj_conv_t* _uj_jis_to_sjis(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_jis_sjis(in, out);
  /* ret == out|NULL */
  return ret;
}


uj_conv_t* _uj_utf8_to_jis(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* conv_ret;
  uj_conv_t* tmp_ret;
  uj_conv_t  tmp_out;

  tmp_ret = _uj_utf8_to_sjis(in, &tmp_out);
  if( tmp_ret!=NULL )
  {
    conv_ret = _uj_sjis_to_jis(&tmp_out, out);
    _uj_conv_move_owner(out, &tmp_out);
    _uj_conv_free_buffer(&tmp_out);
  }else
  {
    conv_ret = NULL;
  }
  return conv_ret;
}

uj_conv_t* _uj_jis_to_utf8(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* conv_ret;
  uj_conv_t* tmp_ret;
  uj_conv_t  tmp_out;

  tmp_ret = _uj_jis_to_sjis(in, &tmp_out);
  if( tmp_ret!=NULL )
  {
    conv_ret = _uj_sjis_to_utf8(&tmp_out, out);
    _uj_conv_move_owner(out, &tmp_out);
    _uj_conv_free_buffer(&tmp_out);
  }else
  {
    conv_ret = NULL;
  }
  return conv_ret;
}

/* ----------------------------------------------------------------------------
: uj_to_jis(uj, &len).
+--------------------------------------------------------------------------- */
uj_uint8* uj_to_jis(const unijp_t* uj, uj_size_t* p_len)
{
  uj_conv_t in;
  uj_conv_t out;
  uj_conv_t* conv_ret;
  uj_uint8* ret_buf;

  _uj_conv_set_const(&in, uj->alloc, uj->data, uj->data_len);
  conv_ret = _uj_utf8_to_jis(&in, &out);
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
