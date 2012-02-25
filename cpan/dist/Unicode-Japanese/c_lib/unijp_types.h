/* ----------------------------------------------------------------------------
 * unijp_types.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_TYPES_H
#define UNIJP_TYPES_H

#ifdef __cplusplus
extern "C"
{
#endif

#include "unijp_int.h"

#include <stddef.h>

typedef size_t uj_size_t;
enum uj_bool { uj_false, uj_true };
typedef enum uj_bool uj_bool;

enum uj_charcode_e {
  ujc_auto,
  ujc_utf8,
  ujc_sjis,
  ujc_eucjp,
  ujc_jis,

  ujc_ucs2,
  ujc_ucs4,
  ujc_utf16,
  ujc_ascii,

  ujc_binary,
  ujc_undefined,
};
typedef enum uj_charcode_e uj_charcode_t;

struct uj_alloc_s
{
  uj_uint32 magic;
  void* baton;
  void* (*alloc)(void* baton, uj_size_t size);
  void* (*realloc)(void* baton, void* ptr, uj_size_t size);
  void  (*free)(void* baton, void* ptr);
};
typedef struct uj_alloc_s uj_alloc_t;
extern const uj_alloc_t* _uj_default_alloc;
#define UJ_ALLOC_MAGIC (0)

struct uj_encname_s
{
  const char*   name;
  uj_charcode_t code;
  uj_bool       is_canon;
  uj_bool       in_ok;
  uj_bool       out_ok;
};
typedef struct uj_encname_s uj_encname_t;
extern const uj_encname_t uj_encnames[];

#ifdef __cplusplus
}
#endif

#endif /* !defined(UNIJP_TYPES_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
