
/* $Id: xs_test.c 4494 2002-10-29 06:23:58Z hio $ */

#include "mediate.h"
#include <unistd.h>   /* memmap */
#include <sys/mman.h> /* memmap */
#include <sys/stat.h> /* stat */
#include <fcntl.h>    /* open */

#ifndef MAP_FAILED
#define MAP_FAILED ((void*)-1)
#endif

void* do_memmap(char* filepath)
{
  int fd;
  struct stat st;
  int res;
  void* ptr;
  
  fd = open(filepath,O_RDONLY|O_NONBLOCK);
  res = fstat(fd,&st);
  if( res==-1 )
  {
    st.st_size = 0;
  }
  ptr = mmap(NULL,st.st_size,PROT_READ,MAP_PRIVATE,fd,0);
  close(fd);
  return ptr;
}

void do_unmemmap(void* ptr)
{
  munmap(ptr,0);
}

