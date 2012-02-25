
#include "unijp.h"
#include "unijp_build.h"

#include <string.h>

void _uj_conv_set_const(uj_conv_t* conv, const uj_alloc_t* alloc, const uj_uint8* str, uj_size_t len)
{
  conv->alloc       = alloc;
  conv->buf         = (uj_uint8*)str; /* const_cast<uj_uint8*>(str) */
  conv->buf_len     = len;
  conv->buf_bufsize = 0;
}

uj_uint8* _uj_conv_own_string(uj_conv_t* conv)
{
  uj_uint8* buf;
  if( conv->buf_bufsize == 0 || conv->buf_bufsize == conv->buf_len )
  {
    uj_size_t new_size = conv->buf_len + 1;
    if( conv->buf_bufsize == 0 )
    {
      buf = _uj_alloc(conv->alloc, new_size);
    }else
    {
      buf = _uj_realloc(conv->alloc, conv->buf, new_size);
    }
    if( buf != NULL )
    {
      memcpy(buf, conv->buf, conv->buf_len);
      buf[conv->buf_len] = '\0';
      conv->buf = buf;
      conv->buf_bufsize = new_size;
    }
  }else
  {
    buf = conv->buf;
  }
  return buf;
}

void _uj_conv_move_owner(uj_conv_t* dst, uj_conv_t* src)
{
  if( dst->buf_bufsize==0 && src->buf_bufsize!=0 )
  {
    dst->buf_bufsize = src->buf_bufsize;
    src->buf_bufsize = 0;
  }
}

void _uj_conv_free_buffer(uj_conv_t* conv)
{
  if( conv->buf_bufsize != 0 )
  {
    _uj_free(conv->alloc, conv->buf);
  }
  conv->buf_len     = 0;
  conv->buf_bufsize = 0;
  conv->buf = (uj_uint8*)"";
}
