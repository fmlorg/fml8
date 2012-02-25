
#include "unijp.h"
#include <stdio.h>
#include <string.h>

int main(int argc, const char* argv[])
{
  unijp_t* uj;
  const char* love_ucs4 = "\x00\x00\x61\x1b";
  const char* love_utf8 = "\xe6\x84\x9b";
  uj_size_t   ucs4_len = 4;
  uj_size_t   utf8_len = 3;

  printf("1..10\n");

  uj = uj_new((uj_uint8*)love_ucs4, ucs4_len, ujc_ucs4);
  printf("ok 1 - new\n");
  printf("%s 2 - uj.len(%d)==%d\n", uj->data_len==utf8_len ? "ok" : "not ok", (int)uj->data_len, (int)utf8_len);
  printf("%s 3 - data\n", memcmp(uj->data, love_utf8, utf8_len)==0 ? "ok" : "not ok");

  {
    uj_uint8*   out;
    uj_size_t   out_len;
    out = uj_to_utf8(uj, &out_len);
    printf("ok 4 - to_utf8\n");
    printf("%s 5 - utf8.len(%d)==%d\n", out_len==utf8_len ? "ok" : "not ok", (int)out_len, (int)utf8_len);
    printf("%s 6 - utf8\n", memcmp(out, love_utf8, utf8_len)==0 ? "ok" : "not ok");
  }

  {
    uj_uint8*   out;
    uj_size_t   out_len;
    out = uj_to_ucs4(uj, &out_len);
    printf("ok 7 - to_ucs4\n");
    printf("%s 8 - ucs4.len(%d)==%d\n", out_len==ucs4_len ? "ok" : "not ok", (int)out_len, (int)ucs4_len);
    printf("%s 9 - ucs4\n", memcmp(out, love_ucs4, ucs4_len)==0 ? "ok" : "not ok");
  }

  uj_delete(uj);
  printf("ok 10 - delete\n");

  return 0;
}
