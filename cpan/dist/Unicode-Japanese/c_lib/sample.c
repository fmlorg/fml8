/* ----------------------------------------------------------------------------
 * $ gcc -Wall -o sample sample.c -L. -lunijp
 * ------------------------------------------------------------------------- */
#include "unijp.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int test_conv(const char* text_utf8, uj_charcode_t ocode)
{
  uj_charcode_t icode = ujc_utf8;
  size_t in_bytes;
  unijp_t* uj;
  uj_uint8* obuf;
  uj_size_t obuf_len;

  in_bytes = strlen(text_utf8);
  uj = uj_new((uj_uint8*)text_utf8, in_bytes, icode);
  if( uj==NULL )
  {
    fprintf(stderr, "uj_new: %s: %s\n", "-", strerror(errno));
    return 1;
  }
  obuf = uj_conv(uj, ocode, &obuf_len);
  if( obuf==NULL )
  {
    fprintf(stderr, "uj_conv: %s: %s\n", "-", strerror(errno));
    return 1;
  }

  printf("sjis result: %s\n", obuf);
  free(obuf);
  uj_delete(uj);

  return 0;
}

int main()
{
  int r;
  const char* text_utf8 = "テスト";

  r = test_conv(text_utf8, ujc_sjis);

  return r;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
