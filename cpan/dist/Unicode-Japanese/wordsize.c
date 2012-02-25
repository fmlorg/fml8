
#include <stdio.h>

int main()
{
  printf( "short = %ld\n", (long)sizeof(short) );
  printf( "int = %ld\n",   (long)sizeof(int)   );
  printf( "long = %ld\n",  (long)sizeof(long)  );
  printf( "void* = %ld\n", (long)sizeof(void*) );
  return 0;
}

