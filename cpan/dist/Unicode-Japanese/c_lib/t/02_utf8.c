
#include "unijp.h"
#include <stdio.h>
#include <string.h>

int main(int argc, const char* argv[])
{
  unijp_t* uj;
  const char* in_str = "そよ風のメヌエット";
  uj_size_t   in_len = strlen(in_str);
  uj_uint8*   out;
  uj_size_t   out_len;

  printf("1..7\n");

  uj = uj_new((uj_uint8*)in_str, in_len, ujc_utf8);
  printf("ok 1 - new\n");
  printf("%s 2 - uj.len(%d)==%d\n", uj->data_len==in_len ? "ok" : "not ok", (int)uj->data_len, (int)in_len);
  printf("%s 3 - data\n", memcmp(uj->data, in_str, in_len)==0 ? "ok" : "not ok");

  out = uj_to_utf8(uj, &out_len);
  printf("ok 4 - to_utf8\n");
  printf("%s 5 - utf8.len(%d)==%d\n", out_len==in_len ? "ok" : "not ok", (int)out_len, (int)in_len);
  printf("%s 6 - utf8\n", memcmp(out, in_str, in_len)==0 ? "ok" : "not ok");

  uj_delete(uj);
  printf("ok 7 - delete\n");

  return 0;
}
