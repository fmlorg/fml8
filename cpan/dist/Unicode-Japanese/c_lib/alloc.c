/* ----------------------------------------------------------------------------
 * alloc.c
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

const uj_alloc_t* _uj_default_alloc;

void* _uj_alloc(const uj_alloc_t* alloc, uj_size_t size)
{
  if( alloc==NULL )
  {
    return malloc(size);
  }else
  {
    return (*alloc->alloc)(alloc->baton, size);
  }
}

void* _uj_realloc(const uj_alloc_t* alloc, void* ptr, uj_size_t size)
{
  if( alloc==NULL )
  {
    return realloc(ptr, size);
  }else
  {
    return (*alloc->realloc)(alloc->baton, ptr, size);
  }
}

void _uj_free(const uj_alloc_t* alloc, void* ptr)
{
  if( alloc==NULL )
  {
    free(ptr);
  }else
  {
    (*alloc->free)(alloc->baton, ptr);
  }
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
