
/* $Id: xs_test.c,v 1.1 2002/01/18 17:17:19 hio Exp $ */

#include "mediate.h"
#include <unistd.h>   // memmap
#include <sys/mman.h> // memmap
#include <sys/stat.h> // stat
#include <fcntl.h>    // open

#ifndef MAP_FAILED
#define MAP_FAILED ((void*)-1)
#endif

void* do_memmap(char* filepath)
{
  int fd = open(filepath,O_RDONLY|O_NONBLOCK);
  struct stat st;
  int res = fstat(fd,&st);
  void* ptr = mmap(NULL,st.st_size,PROT_READ,MAP_PRIVATE,fd,0);
  close(fd);
  return ptr;
}

void do_unmemmap(void* ptr)
{
  munmap(ptr,0);
}

