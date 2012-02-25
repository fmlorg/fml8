/* ----------------------------------------------------------------------------
 * any_to_utf8.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "unijp.h"
#include "unijp_build.h"

#include <stdlib.h>

/* ----------------------------------------------------------------------------
: _uj_any_to_utf8(conv, icode).
+--------------------------------------------------------------------------- */
uj_conv_t* _uj_any_to_utf8(const uj_conv_t* in, uj_conv_t* out, uj_charcode_t icode)
{
  if( icode==ujc_auto )
  {
    icode = uj_getcode(in->buf, in->buf_len);
  }
  switch( icode )
  {
  case ujc_auto:      abort();
  case ujc_utf8:      return _uj_validate_utf8(in, out);
  case ujc_sjis:      return _uj_sjis_to_utf8(in, out);
  case ujc_eucjp:     return _uj_eucjp_to_utf8(in, out);
  case ujc_jis:       return _uj_jis_to_utf8(in, out);
  case ujc_ucs2:      return _uj_ucs2_to_utf8(in, out);
  case ujc_ucs4:      return _uj_ucs4_to_utf8(in, out);
  case ujc_utf16:     return _uj_utf16_to_utf8(in, out);
  case ujc_ascii:     return _uj_validate_utf8(in, out);
  case ujc_binary:    abort();
  case ujc_undefined: abort();
  }
  abort();
  return NULL;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
