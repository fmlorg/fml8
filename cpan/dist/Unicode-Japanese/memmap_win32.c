
/* $Id$ */

#include "Japanese.h"
#include <windows.h>
#include <tchar.h>
#include <stdio.h>

#if PERL_REVISION <= 5 && PERL_VERSION < 5
/* copy from libwin32-0.24/APIFile/File.xs */
/* Perl 5.005 added win32_get_osfhandle/win32_open_osfhandle */
# define win32_get_osfhandle _get_osfhandle
# define win32_open_osfhandle _open_osfhandle
# ifdef _get_osfhandle
#  undef _get_osfhandle/* stolen_get_osfhandle() isn't available here */
# endif
# ifdef _open_osfhandle
#  undef _open_osfhandle /* stolen_open_osfhandle() isn't available here */
# endif
#endif


/* easy win32 strerror. */
static LPTSTR getLastErrorMessage(void);

/* win32 native file/mmap object */
static HANDLE* hFile_pmfile;
static HANDLE* hFileMapping;


/* pointer to mapped file */
static char* s_mmap_pmfile;
static int   s_mmap_pmfile_size;

/* split mapping table. */
extern void do_memmap_set(const char* mmap_pmfile, int mmap_pmfile_size);

/* ----------------------------------------------------------------------------
 * 必要なファイルをメモリにマッピング
 */
void
do_memmap(void)
{
  int fd_pmfile;
  DWORD dwFileSizeLow, dwFileSizeHigh;
  
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
    
    hFile_pmfile = (HANDLE)win32_get_osfhandle(fd_pmfile);
    if( hFile_pmfile==INVALID_HANDLE_VALUE )
    {
      croak("Unicode::Japanese#do_memmap, could not get native handle for fd [%d]", fd_pmfile);
    }
    dwFileSizeLow = GetFileSize(hFile_pmfile,&dwFileSizeHigh);
    if( dwFileSizeLow==-1 && GetLastError()!=NO_ERROR )
    {
      croak("Unicode::Japanese#do_memmap, %s failed","GetFileSize");
    }
  }
  
  {
    /* mmap */
    hFileMapping = CreateFileMapping(hFile_pmfile,NULL,PAGE_READONLY,dwFileSizeHigh,dwFileSizeLow,NULL);
    if( hFileMapping==NULL )
    {
      croak("Unicode::Japanese#do_memmap, %s failed","CreateFileMapping");
    }
    s_mmap_pmfile_size = dwFileSizeLow;
    s_mmap_pmfile = MapViewOfFile(hFileMapping,FILE_MAP_READ,0,0,s_mmap_pmfile_size);
    if( s_mmap_pmfile==NULL )
    {
      croak("Unicode::Japanese#do_memmap, %s failed","MapViewOfFile");
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
    UnmapViewOfFile(s_mmap_pmfile);
    s_mmap_pmfile;
  }
  if( hFileMapping!=NULL )
  {
    CloseHandle(hFileMapping);
    hFileMapping = NULL;
  }
  if( hFile_pmfile!=NULL )
  {
    /* this handle is opened by perl, and not duped. */
    /* no need CloseHandle. */
    hFile_pmfile = NULL;
  }
  
  return;
}

/* ----------------------------------------------------------------------------
 * LPTSTR message = getLastErrorMessage();
 * LPTSTR message = getErrorMessage(DWORD errorCode);
 *   エラーメッセージの取得 
 *   取得したメッセージは LocalFree で解放してね☆ 
 */
static LPTSTR getErrorMessage(DWORD errcode);
static LPTSTR getLastErrorMessage(void)
{
  return getErrorMessage(GetLastError());
}
static LPTSTR getErrorMessage(DWORD errcode)
{
  LPVOID lpMessage;
  DWORD msglen;
  lpMessage = NULL;
  msglen = FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER
			  | FORMAT_MESSAGE_FROM_SYSTEM
			  | FORMAT_MESSAGE_IGNORE_INSERTS,
			  NULL,
			  errcode,
			  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* 既定の言語 */
			  (LPTSTR)&lpMessage,
			  0,
			  NULL
			  );
  if( msglen==0 )
  {
    if( lpMessage )
    {
      lpMessage = LocalReAlloc(lpMessage,64,0);
    }else
    {
      lpMessage = LocalAlloc(LMEM_FIXED,64);
    }
    if( lpMessage )
    {
      _sntprintf((LPTSTR)lpMessage,64,
		 TEXT("Unknown Error (%lu,0x%08x)\n"),
		 errcode, errcode
		 );
    }
  }
  return lpMessage;
}

