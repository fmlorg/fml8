
/* $Id$ */

#include "Japanese.h"
#include <unistd.h>   /* memmap */
#include <sys/mman.h> /* memmap */
#include <sys/stat.h> /* stat   */
#include <fcntl.h>    /* open   */

#ifndef MAP_FAILED
#define MAP_FAILED ((void*)-1)
#endif

/* pointer to mapped file */
static char* s_mmap_pmfile;
static int   s_mmap_pmfile_size;

/* split mapping table. */
extern void do_memmap_set(const char* mmap_pmfile, int mmap_pmfile_size);

/* ----------------------------------------------------------------------------
 * mmap data files.
 */
void
do_memmap(void)
{
  int fd_pmfile;
  struct stat st_pmfile;
  
  {
    /* (ja)初期化を確認 */
    /* ensure initialize. */
    SV* sv = get_sv("Unicode::Japanese::PurePerl::HEADLEN",0);
    if( sv==NULL || !SvOK(sv) )
    { /* not loaded yet. */
      /* load now. */
      call_pv("Unicode::Japanese::PurePerl::_init_table",G_NOARGS|G_DISCARD);
    }
  }
  
  {
    /* get file descriptor and size. */
    SV* sv_fd;
    sv_fd = eval_pv("fileno($Unicode::Japanese::PurePerl::FH)",G_KEEPERR|G_SCALAR|G_NOARGS);
    if( sv_fd==NULL || !SvOK(sv_fd) || !SvIOK(sv_fd) )
    {
      croak("Unicode::Japanese#do_memmap, could not get fd of FH");
    }
    fd_pmfile = SvIV(sv_fd);
    if( fstat(fd_pmfile,&st_pmfile)!=0 )
    {
      croak("Unicode::Japanese#do_memmap, stat failed: fd [%d]: %s",fd_pmfile,strerror(errno));
    }
  }
  
  {
    /* mmap */
    s_mmap_pmfile_size = st_pmfile.st_size;
    s_mmap_pmfile = (char*)mmap(NULL,s_mmap_pmfile_size,PROT_READ,MAP_PRIVATE,fd_pmfile,0);
    if( s_mmap_pmfile==MAP_FAILED )
    {
      s_mmap_pmfile = NULL;
      croak("Unicode::Japanese#do_memmap, mmap failed: %s",strerror(errno));
    }
  }
  
  /* bind each table. */
  do_memmap_set(s_mmap_pmfile,s_mmap_pmfile_size);
  
  return;
}

/* ----------------------------------------------------------------------------
 * メモリマップの解除
 */
void
do_memunmap(void)
{
  /* printf("* do_memunmap() *\n"); */

  if( s_mmap_pmfile!=NULL )
  {
    if( munmap(s_mmap_pmfile,s_mmap_pmfile_size)==-1 )
    {
      Perl_warn(aTHX_ "Unicode::Japanese#do_memunmap, munmap failed: %s",strerror(errno));
    }
  }
  
  return;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
