/* ----------------------------------------------------------------------------
 * utf8_to_any.c
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
: uj_conv(uj, ocode, &len).
+--------------------------------------------------------------------------- */
uj_uint8* uj_conv(unijp_t* uj, uj_charcode_t ocode, uj_size_t* p_len)
{
  switch( ocode )
  {
  case ujc_auto:      abort();
  case ujc_utf8:      return uj_to_utf8(uj, p_len);
  case ujc_sjis:      return uj_to_sjis(uj, p_len);
  case ujc_eucjp:     return uj_to_eucjp(uj, p_len);
  case ujc_jis:       return uj_to_jis(uj, p_len);
  case ujc_ucs2:      return uj_to_ucs2(uj, p_len);
  case ujc_ucs4:      return uj_to_ucs4(uj, p_len);
  case ujc_utf16:     return uj_to_utf16(uj, p_len);
  case ujc_ascii:     abort();
  case ujc_binary:    abort();
  case ujc_undefined: abort();
  }
  abort();
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
