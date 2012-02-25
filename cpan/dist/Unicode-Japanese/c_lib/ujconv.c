/* ----------------------------------------------------------------------------
 * ujconv.c
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

#define UJCONV_VERSION "0.01"

static void print_encodings(void);
static void print_usage(void);
static void print_version(void);

int main(int argc, const char* argv[])
{
  uj_charcode_t icode;
  uj_charcode_t ocode;
  const char* files[10];
  int end_of_opts;
  int nr_files;
  int i;

  icode = ujc_auto;
  ocode = ujc_auto;
  nr_files = 0;
  end_of_opts = 0;
  for( i=1; i<argc; ++i )
  {
    if( argv[i][0]=='-' && argv[i][1]!='\0' && !end_of_opts )
    {
      if( strcmp(argv[i], "-f")==0 || strcmp(argv[i], "--from")==0 )
      {
        ++i;
        if( i==argc )
        {
          fprintf(stderr, "no argument for %s\n", argv[i-1]);
          return 1;
        }
        icode = uj_charcode_parse(argv[i]);
        if( icode==ujc_undefined )
        {
          fprintf(stderr, "unknown encoding: %s\n", argv[i]);
          return 1;
        }
      }else if( strcmp(argv[i], "-t")==0 || strcmp(argv[i], "--to")==0 )
      {
        ++i;
        if( i==argc )
        {
          fprintf(stderr, "no argument for %s\n", argv[i-1]);
          return 1;
        }
        ocode = uj_charcode_parse(argv[i]);
        if( ocode==ujc_undefined )
        {
          fprintf(stderr, "unknown encoding: %s\n", argv[i]);
          return 1;
        }
      }else if( strcmp(argv[i], "-l")==0 || strcmp(argv[i], "--list")==0 )
      {
        print_encodings();
        return 0;
      }else if( strcmp(argv[i], "-h")==0 || strcmp(argv[i], "--help")==0 )
      {
        print_usage();
        return 0;
      }else if( strcmp(argv[i], "-V")==0 || strcmp(argv[i], "--version")==0 )
      {
        print_version();
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
  if( nr_files==0 )
  {
    files[nr_files++] = "-";
  }

  if( ocode==ujc_auto )
  {
    ocode = ujc_utf8;
  }


  {
    char* buf;
    int buf_size;
    int buf_len;

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
      while( fgets(buf, 1023, fp)!=NULL )
      {
        size_t rlen;
        size_t wlen;
        unijp_t* uj;
        uj_uint8* obuf;
        uj_size_t obuf_len;

        rlen = strlen(buf);
        uj = uj_new((uj_uint8*)buf, rlen, icode);
        if( uj==NULL )
        {
          fprintf(stderr, "uj_new: %s: %s\n", files[i], strerror(errno));
          return 1;
        }
        obuf = uj_conv(uj, ocode, &obuf_len);
        if( obuf==NULL )
        {
          fprintf(stderr, "uj_conv: %s: %s\n", files[i], strerror(errno));
          return 1;
        }
        wlen = fwrite(obuf, 1, obuf_len,  stdout);
        if( wlen!=obuf_len )
        {
          fprintf(stderr, "fwrite: %s: %s\n", files[i], strerror(errno));
          return 1;
        }
        free(obuf);
        uj_delete(uj);
      }
      if( ferror(fp) )
      {
        fprintf(stderr, "fread: %s: %s\n", files[i], strerror(errno));
        return 1;
      }
      fclose(fp);
    }
    free(buf);
  }
  return 0;
}

static void print_encodings(void)
{
  const uj_encname_t* p;
  for( p=&uj_encnames[0]; p->name; ++p )
  {
    printf("%s\n", p->name);
  }
  return;
}

static void print_usage(void)
{
  printf("usage: ujconv [options..] [files..]\n");
  printf("options:\n");
  printf("-f, --from     icode\n");
  printf("-t, --to       ocode\n");
  printf("-l, --list     list available encodings\n");
  printf("-h, --help     show this usage\n");
  printf("-V, --version  show version information\n");
  return;
}

static void print_version(void)
{
  printf("version %s\n",          UJCONV_VERSION);
  printf("libunijp version %s\n", UNIJP_VERSION_STRING);
  return;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
