/* ----------------------------------------------------------------------------
 * unijp.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "unijp.h"
#include "unijp_build.h"

/* ----------------------------------------------------------------------------
: uj_new(str, bytes_len, icode).
+--------------------------------------------------------------------------- */
unijp_t* uj_new(const uj_uint8* str, uj_size_t bytes, uj_charcode_t icode)
{
  unijp_t* uj;
  uj_conv_t conv_in;
  uj_conv_t conv_out;
  uj_conv_t* conv_ret;
  const uj_alloc_t* const alloc = _uj_default_alloc;

  _uj_conv_set_const(&conv_in, alloc, str, bytes);
  conv_ret = _uj_any_to_utf8(&conv_in, &conv_out, icode);
  if( conv_ret != NULL )
  {
    uj = _uj_alloc(alloc, sizeof(*uj));
    if( uj!=NULL )
    {
      _uj_conv_own_string(&conv_out);
      uj->alloc     = _uj_default_alloc;
      uj->data      = conv_out.buf;
      uj->data_len  = conv_out.buf_len;
      uj->is_binary = icode==ujc_binary;
    }else
    {
      _uj_conv_free_buffer(&conv_out);
    }
  }else
  {
    uj = NULL;
  }
  return uj;
}

/* ----------------------------------------------------------------------------
: uj_delete(uj).
+--------------------------------------------------------------------------- */
void uj_delete(unijp_t* uj)
{
  _uj_free(uj->alloc, uj->data);
  _uj_free(uj->alloc, uj);
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
