
// $Id: memmap.cpp,v 1.9 2002/06/25 16:30:27 hio Exp $

#include "Japanese.h"
#include <unistd.h>   // memmap
#include <sys/mman.h> // memmap
#include <sys/stat.h> // stat
#include <fcntl.h>    // open

#ifndef MAP_FAILED
#define MAP_FAILED ((void*)-1)
#endif

EXTERN_C
{
  /* SJIS <=> UTF8 変換テーブル */
  unsigned short const* g_u2s_table;
  unsigned long  const* g_s2u_table;

  /* i-mode/j-sky/dot-i絵文字 <=> UTF8 変換テーブル */
  unsigned long  const* g_ei2u_table;
  unsigned short const* g_eu2i_table;
  unsigned long  const* g_ej2u_table;
  unsigned char  const* g_eu2j_table; // char [][5]
  unsigned long  const* g_ed2u_table;
  unsigned short const* g_eu2d_table;

  /* i-mode/j-sky/dot-i絵文字 <=> UTF8 変換テーブルの要素数 */
  /* バイト数でなく要素数                                   */
  int g_ei2u_size;
  int g_eu2i_size;
  int g_ej2u_size;
  int g_eu2j_size;
  int g_ed2u_size;
  int g_eu2d_size;

  /* メモリマップの情報 */
  static int   g_mmap_u2s_length;
  static char* g_mmap_u2s_start;
  static int   g_mmap_emj_length;
  static char* g_mmap_emj_start;

}

static int
findfile(AV* INC, const char* filename)
{
  //fprintf(stderr,"findfile [%s]\n",filename);
  int i;
  char  path[PATH_MAX];
  int addlen = strlen(filename);
  for( i=0; i<av_len(INC); ++i )
  {
    SV** dir = av_fetch(INC,i,0);
    int len = sv_len(*dir);
    if( len==0 ) continue;
    if( len+addlen+2>=PATH_MAX ) continue;
    memcpy(path,SvPV(*dir,PL_na),len);
    if( path[len]!='/' ) path[len++] = '/';
    memcpy(path+len,filename,addlen);
    path[len+addlen] = '\0';
    //fprintf(stderr,"  trying [%s] ...\n",path);
    int fd = open(path,O_RDONLY|O_NONBLOCK);
    if( fd!=-1 )
    {
      //fprintf(stderr,"findfile [%s] found\n",filename);
      return fd;
    }
  }
  //fprintf(stderr,"findfile [%s] failed\n",filename);
  return -1;
}

void
do_memmap()
{
  //fprintf(stderr,"* Unicode::Japanese::(xs)do_memmap *\n");
  AV* INC = get_av("INC",0);
  if( INC==NULL )
  {
    Perl_croak(aTHX_ "do_memmap, cannot get @INC.");
    return;
  }
  int fd_u2s = findfile(INC,"Unicode/Japanese/u2s-s2u.dat");
  int fd_emj = findfile(INC,"Unicode/Japanese/emoji.dat");

  if( fd_u2s==-1 || fd_emj==-1 )
  {
    if( fd_u2s!=-1 )
    {
      Perl_croak(aTHX_ "do_memmap, emoji table not found or could not  open.");
    }else if( fd_emj!=-1 )
    {
      Perl_croak(aTHX_ "do_memmap, u2s table not found or could not open.");
    }else
    {
      Perl_croak(aTHX_ "do_memmap, u2s table and emoji table not found or could not open.");
    }
    return;
  }
  struct stat st_u2s,st_emj;
  int res_u2s = fstat(fd_u2s,&st_u2s);
  int res_emj = fstat(fd_emj,&st_emj);
  if( res_u2s==-1 && res_emj==-1 )
  {
    if( res_u2s!=-1 )
    {
      Perl_croak(aTHX_ "do_memmap, stat emoji table (for mmap) failed.");
    }else if( res_emj!=-1 )
    {
      Perl_croak(aTHX_ "do_memmap, stat u2s table (for mmap) failed.");
    }else
    {
      Perl_croak(aTHX_ "do_memmap, stat u2s and emoji tables (for mmap) failed.");
    }
    close(fd_u2s);
    close(fd_emj);
    return;
  }

  if( st_u2s.st_size!=0x60000 )
  {
    Perl_croak(aTHX_ "do_memmap, u2s-s2u size != 0x60000, [got %#x].",st_u2s.st_size);
    return;
  }
  if( st_emj.st_size!=0xb800 )
  {
    Perl_croak(aTHX_ "do_memmap, emoji.dat size != 0xb800, [got %#x].",st_emj.st_size);
    return;
  }

  g_mmap_u2s_length  = st_u2s.st_size;
  g_mmap_u2s_start = (char*)mmap(NULL,g_mmap_u2s_length,PROT_READ,MAP_PRIVATE,fd_u2s,0);
  g_mmap_emj_length  = st_emj.st_size;
  g_mmap_emj_start = (char*)mmap(NULL,g_mmap_emj_length,PROT_READ,MAP_PRIVATE,fd_emj,0);

  close(fd_u2s);
  close(fd_emj);

  if( g_mmap_u2s_start==MAP_FAILED || g_mmap_emj_start==MAP_FAILED )
  {
    if( g_mmap_u2s_start!=MAP_FAILED )
    {
      Perl_croak(aTHX_ "do_memmap, mmap emoji table failed.");
      g_mmap_emj_start = NULL;
    }else if( g_mmap_emj_start!=MAP_FAILED )
    {
      Perl_croak(aTHX_ "do_memmap, mmap u2s table failed.");
      g_mmap_u2s_start = NULL;
    }else
    {
      Perl_croak(aTHX_ "do_memmap, mmap u2s and emoji table failed.");
      g_mmap_u2s_start = NULL;
      g_mmap_emj_start = NULL;
    }
    do_memunmap();
    return;
  }

  // u2s,s2uの設定
  g_u2s_table = (unsigned short*)(g_mmap_u2s_start +     0x0);
  g_s2u_table = (unsigned long *)(g_mmap_u2s_start + 0x20000);

  // i-mode
  g_eu2i_table = (unsigned short*)(g_mmap_emj_start +    0x0); // +0x2000
  g_eu2i_size  = 0x2000/2;
  g_ei2u_table = (unsigned long *)(g_mmap_emj_start + 0x2000); // +0x800
  g_ei2u_size  = 0x800/4;
  g_eu2j_table = (unsigned char *)(g_mmap_emj_start + 0x2800); // +0x5000
  g_eu2j_size  = 0x5000/1;
  g_ej2u_table = (unsigned long *)(g_mmap_emj_start + 0x7800); // +0xc00
  g_ej2u_size  = 0xc00/4;
  g_eu2d_table = (unsigned short*)(g_mmap_emj_start + 0x8400); // +0x2000
  g_eu2d_size  = 0x2000/2;
  g_ed2u_table = (unsigned long *)(g_mmap_emj_start + 0xa400); // +0x1400
  g_ed2u_size  = 0x1400/4;
}

void
do_memunmap()
{
  // printf("* do_memunmap() *\n");

  // u2s table
  if( g_mmap_u2s_start!=NULL )
  {
    int res = munmap(g_mmap_u2s_start,g_mmap_u2s_length);
    if( res==-1 )
    {
      Perl_croak(aTHX_ "do_memunmap, munmap u2s table failed.");
    }
  }
  // emoji table
  if( g_mmap_emj_start!=NULL )
  {
    int res = munmap(g_mmap_emj_start,g_mmap_emj_length);
    if( res==-1 )
    {
      Perl_croak(aTHX_ "do_memunmap, munmap emoji table failed.");
    }
  }
}
