
#include "unijp.h"
#include <stdio.h>

int main(int argc, const char* argv[])
{
  unijp_t* uj;
  printf("1..2\n");
  uj = uj_new((uj_uint8*)"", 0, ujc_utf8);
  printf("ok 1 - new\n");
  uj_delete(uj);
  printf("ok 2 - delete\n");
  return 0;
}
