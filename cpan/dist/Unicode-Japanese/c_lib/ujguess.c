/* ----------------------------------------------------------------------------
 * ujguess.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "unijp.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define UJGUESS_VERSION "0.01"

int main(int argc, const char* argv[])
{
  const char* files[10];
  int end_of_opts;
  int nr_files;
  int no_filename;
  int show_filename;
  int i;

  nr_files      = 0;
  end_of_opts   = 0;
  no_filename   = 0;
  show_filename = 0;
  for( i=1; i<argc; ++i )
  {
    if( argv[i][0]=='-' && argv[i][1]!='\0' && !end_of_opts )
    {
      if( strcmp(argv[i], "--no-filename")==0 )
      {
        no_filename   = 1;
        show_filename = 0;
      }else if( strcmp(argv[i], "--show-filename")==0 )
      {
        no_filename   = 0;
        show_filename = 1;
      }else if( strcmp(argv[i], "-h")==0 || strcmp(argv[i], "--help")==0 )
      {
        printf("usage: ujguess [options..] [files..]\n");
        printf("options:\n");
        printf("-h, --help     show this usage\n");
        printf("-V, --version  show version information\n");
        return 0;
      }else if( strcmp(argv[i], "-V")==0 || strcmp(argv[i], "--version")==0 )
      {
        printf("version %s\n", UJGUESS_VERSION);
        printf("libunijp version %s\n", UNIJP_VERSION_STRING);
        return 0;
      }else if( strcmp(argv[i], "--")==0 )
      {
        end_of_opts = 1;
      }else
      {
        fprintf(stderr, "invalid option: %s\n", argv[i]);
        return 1;
      }
    }else
    {
      if( nr_files==10 )
      {
        fprintf(stderr, "too many files\n");
        return 1;
      }
      files[nr_files++] = argv[i];
    }
  }
  if( !no_filename && !show_filename )
  {
    if( nr_files >= 2 )
    {
      show_filename = 1;
    }else
    {
      no_filename   = 1;
    }
  }
  if( nr_files==0 )
  {
    files[nr_files++] = "-";
  }


  {
    char* buf;
    size_t buf_size;
    size_t buf_len;

    buf_len = 0;
    buf_size = 1024;
    buf = malloc(buf_size);
    if( buf==NULL )
    {
      fprintf(stderr, "malloc: %s\n", strerror(errno));
      return 1;
    }

    for( i=0; i<nr_files; ++i )
    {
      FILE* fp;
      uj_charcode_t code;
      int use_stdin = strcmp(files[i], "-")==0;
      if( use_stdin )
      {
        fp = stdin;
      }else
      {
        fp = fopen(files[i], "r");
        if( fp==NULL )
        {
          fprintf(stderr, "fopen: %s: %s\n", files[i], strerror(errno));
          return 1;
        }
      }

      buf_len = 0;
      while( fgets(buf+buf_len, 1023, fp)!=NULL )
      {
        char* new_buf;
        size_t rlen;
        rlen = strlen(buf+buf_len);
        buf_len += rlen;
        buf_size += 1024;
        new_buf = realloc(buf, buf_size);
        if( new_buf==0 )
        {
          fprintf(stderr, "realloc: %s: %s\n", files[i], strerror(errno));
          return 1;
        }
        buf = new_buf;
      }
      if( ferror(fp) )
      {
        fprintf(stderr, "fread: %s: %s\n", files[i], strerror(errno));
        return 1;
      }
      fclose(fp);

      code = uj_getcode((uj_uint8*)buf, buf_len);
      if( !no_filename )
      {
        printf("%s:", files[i]);
      }
      printf("%s\n", uj_charcode_str(code));
    }
    free(buf);
  }
  return 0;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
