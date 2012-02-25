/* ----------------------------------------------------------------------------
 * xs_compat.c
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

uj_conv_t* _uj_conv_new_strn(const uj_alloc_t* alloc, const char* str, uj_size_t len)
{
  uj_conv_t* conv;
  uj_uint8* buf;
  buf = _uj_alloc(alloc, len);
  if( buf!=NULL )
  {
    memcpy(buf, str, len+1);
    buf[len] = '\0';
    conv = _uj_alloc(alloc, sizeof(*conv));
    if( conv!=NULL )
    {
      conv->alloc       = alloc;
      conv->buf         = buf;
      conv->buf_len     = len;
      conv->buf_bufsize = len+1;
    }else
    {
      _uj_free(alloc, buf);
    }
  }else
  {
    conv = NULL;
  }
  return conv;
}

uj_conv_t* _uj_conv_clone(const uj_conv_t* conv)
{
  uj_conv_t* clone;
  if( conv != NULL && conv != &_uj_xs_conv_undef )
  {
    clone = _uj_conv_new_strn(conv->alloc, (char*)conv->buf, conv->buf_len);
  }else
  {
    abort();
  }
  return clone;
}

uj_uint8* _uj_conv_grow(uj_conv_t* conv, uj_size_t new_bufsize)
{
  uj_uint8* new_buf;
  if( conv->buf_bufsize==0 )
  {
    new_buf = _uj_alloc(conv->alloc, new_bufsize);
    if( new_buf!=NULL )
    {
      memcpy(new_buf, conv->buf, conv->buf_len);
    }
  }else
  {
    new_buf = _uj_realloc(conv->alloc, conv->buf, new_bufsize);
  }
  if( new_buf!=NULL )
  {
    conv->buf = new_buf;
    conv->buf_bufsize = new_bufsize;
  }
  return new_buf;
}

const uj_conv_t _uj_xs_conv_undef;
uj_size_t _uj_xs_PL_na;

void _uj_xs_SV_Buf_append_ch(uj_conv_t* conv, int ch)
{
  if( conv->buf_len+1 > conv->buf_bufsize )
  {
    _uj_conv_grow(conv, conv->buf_len+100);
  }
  conv->buf[conv->buf_len++] = (uj_uint8)ch;
  return;
}

void _uj_xs_SV_Buf_append_ch2(uj_conv_t* conv, int ch)
{
  uj_uint16 buf;
  if( conv->buf_len+2 > conv->buf_bufsize )
  {
    _uj_conv_grow(conv, conv->buf_len+100);
  }
  buf = (uj_uint16)ch;
  memcpy(conv->buf+conv->buf_len, &buf, 2);
  conv->buf_len += 2;
  return;
}

void _uj_xs_SV_Buf_append_ch3(uj_conv_t* conv, int ch)
{
  uj_uint32 buf;
  if( conv->buf_len+3 > conv->buf_bufsize )
  {
    _uj_conv_grow(conv, conv->buf_len+100);
  }
  buf = ch;
  memcpy(conv->buf+conv->buf_len, &buf, 3);
  conv->buf_len += 3;
  return;
}

void _uj_xs_SV_Buf_append_ch4(uj_conv_t* conv, int ch)
{
  uj_uint32 buf;
  if( conv->buf_len+4 > conv->buf_bufsize )
  {
    _uj_conv_grow(conv, conv->buf_len+100);
  }
  buf = ch;
  memcpy(conv->buf+conv->buf_len, &buf, 4);
  conv->buf_len += 4;
  return;
}

void _uj_xs_SV_Buf_append_mem(uj_conv_t* conv, const uj_uint8* ptr, int len)
{
  if( conv->buf_bufsize <= conv->buf_len + len )
  {
    _uj_conv_grow(conv, conv->buf_len + len + 100);
  }
  memcpy(conv->buf + conv->buf_len, ptr, len);
  conv->buf_len += len;
  return;
}

void _uj_xs_SV_Buf_append_entityref(uj_conv_t* conv, int ch)
{
  char tmpbuf[30];
  int write_len = snprintf(tmpbuf, sizeof(tmpbuf), "&#%u;", ch);
  if( write_len!=-1 && write_len<32 )
  {
    _uj_xs_SV_Buf_append_mem(conv, (uj_uint8*)tmpbuf, write_len);
  }else
  {
    _uj_xs_SV_Buf_append_ch(conv, '?');
  }
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
