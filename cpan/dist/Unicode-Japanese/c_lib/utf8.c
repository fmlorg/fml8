/* ----------------------------------------------------------------------------
 * utf8.c
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
#define xs_validate_utf8(decl) _uj_xs_validate_utf8(const uj_conv_t* sv_str, uj_conv_t* __out)

#include "../utf8.c"
#undef xs_validate_utf8
#define xs_validate_utf8(in,out) _uj_xs_validate_utf8(in,out)

uj_conv_t* _uj_validate_utf8(const uj_conv_t* in, uj_conv_t* out)
{
  uj_conv_t* ret;
  ret = xs_validate_utf8(in, out);
  /* ret == out|NULL */
  return ret;
}

#include <string.h>

/* ----------------------------------------------------------------------------
: uj_to_utf8(uj, &len).
+--------------------------------------------------------------------------- */
uj_uint8* uj_to_utf8(const unijp_t* uj, uj_size_t* p_len)
{
  uj_uint8* clone;
  clone = _uj_alloc(uj->alloc, uj->data_len);
  if( clone!=NULL )
  {
    memcpy(clone, uj->data, uj->data_len);
    if( p_len!=NULL )
    {
      *p_len = uj->data_len;
    }
  }
  return clone;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
