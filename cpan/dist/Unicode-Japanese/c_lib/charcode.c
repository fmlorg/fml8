/* ----------------------------------------------------------------------------
 * charcode.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "unijp.h"
#include "unijp_build.h"

#include <string.h>

const uj_encname_t uj_encnames[] = {
  /* name:    code:        is_canon:  in_ok:   out_ok: */
  { "auto",   ujc_auto,    uj_false,  uj_true, uj_false },
  { "utf8",   ujc_utf8,    uj_true,   uj_true, uj_true  },
  { "sjis",   ujc_sjis,    uj_true,   uj_true, uj_true  },
  { "eucjp",  ujc_eucjp,   uj_true,   uj_true, uj_true  },
  { "euc",    ujc_eucjp,   uj_false,  uj_true, uj_true  },
  { "jis",    ujc_jis,     uj_true,   uj_true, uj_true  },
  { "ucs2",   ujc_ucs2,    uj_true,   uj_true, uj_true  },
  { "ucs4",   ujc_ucs4,    uj_true,   uj_true, uj_true  },
  { "utf16",  ujc_utf16,   uj_true,   uj_true, uj_true  },
  { "ascii",  ujc_ascii,   uj_true,   uj_true, uj_true  },
  { "binary", ujc_binary,  uj_true,   uj_true, uj_true  },
  { NULL, 0 },
};

/* ----------------------------------------------------------------------------
: uj_charcode_parse(str).
+--------------------------------------------------------------------------- */
uj_charcode_t uj_charcode_parse(const char* name)
{
  const uj_encname_t* p;
  for( p=&uj_encnames[0]; p->name; ++p )
  {
    if( strcmp(name, p->name)==0 )
    {
      return p->code;
    }
  }
  return ujc_undefined;
}

/* ----------------------------------------------------------------------------
: uj_charcode_parse_n(str, str_len).
+--------------------------------------------------------------------------- */
uj_charcode_t uj_charcode_parse_n(const char* name, int str_len)
{
  const uj_encname_t* p;
  for( p=&uj_encnames[0]; p->name; ++p )
  {
    if( strncmp(name, p->name, str_len)==0 && p->name[str_len]=='\0' )
    {
      return p->code;
    }
  }
  return ujc_undefined;
}

/* ----------------------------------------------------------------------------
: uj_charcode_str(code).
+--------------------------------------------------------------------------- */
const char*   uj_charcode_str(uj_charcode_t code)
{
  const uj_encname_t* p;
  for( p=&uj_encnames[0]; p->name; ++p )
  {
    if( p->code==code )
    {
      return p->name;
    }
  }
  return "undefined";
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
