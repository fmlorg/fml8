/* ----------------------------------------------------------------------------
 * memmap_common.c
 * memmap, common routines.
 * ----------------------------------------------------------------------------
 * Mastering programed by YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "Japanese.h"

/* SJIS <=> UTF8 mapping table      */
/* (ja:) SJIS <=> UTF8 変換テーブル */
/* index is in 0..0xffff            */
UJ_UINT8 const* g_u2s_table;
UJ_UINT8 const* g_s2u_table;

/* i-mode/j-sky/dot-i絵文字 <=> UTF8 変換テーブル */
UJ_UINT32 const* g_ei2u1_table;
UJ_UINT32 const* g_ei2u2_table;
UJ_UINT16 const* g_eu2i1_table;
UJ_UINT16 const* g_eu2i2_table;
UJ_UINT32 const* g_ej2u1_table;
UJ_UINT32 const* g_ej2u2_table;
UJ_UINT8  const* g_eu2j1_table; /* char [][5] */
UJ_UINT8  const* g_eu2j2_table; /* char [][5] */
UJ_UINT32 const* g_ed2u_table;
UJ_UINT16 const* g_eu2d_table;

/* i-mode/j-sky/dot-i絵文字 <=> UTF8 変換テーブルの要素数 */
/* バイト数でなく要素数                                   */
int g_ei2u1_size;
int g_ei2u2_size;
int g_eu2i1_size;
int g_eu2i2_size;
int g_ej2u1_size;
int g_ej2u2_size;
int g_eu2j1_size;
int g_eu2j2_size;
int g_ed2u_size;
int g_eu2d_size;

/* au <=> ut8 */
UJ_UINT32 const* g_ea2u1_table;
int              g_ea2u1_size;
UJ_UINT32 const* g_ea2u2_table;
int              g_ea2u2_size;
UJ_UINT16 const* g_eu2a1_table;
int              g_eu2a1_size;
UJ_UINT16 const* g_eu2a2_table;
int              g_eu2a2_size;
/* au(s) <=> ut8 */
UJ_UINT32 const* g_ea2u1s_table;
int              g_ea2u1s_size;
UJ_UINT32 const* g_ea2u2s_table;
int              g_ea2u2s_size;
UJ_UINT16 const* g_eu2a1s_table;
int              g_eu2a1s_size;
UJ_UINT16 const* g_eu2a2s_table;
int              g_eu2a2s_size;


/* ----------------------------------------------------------------------------
 * split mapping table.
 */
void
do_memmap_set(const char* mmap_pmfile, int mmap_pmfile_size)
{
  HV* hv_table;
  int headlen, proglen;
  
  assert( mmap_pmfile!=NULL );
  assert( mmap_pmfile_size!=0 );
  
  {
    SV* sv;
    sv = get_sv("Unicode::Japanese::PurePerl::HEADLEN",0);
    assert( sv!=NULL && "HEADLEN is not NULL");
    headlen = SvIV(sv);
    assert( headlen>0 );
    sv = get_sv("Unicode::Japanese::PurePerl::PROGLEN",0);
    assert( sv!=NULL && "PROGLEN is not NULL");
    proglen = SvIV(sv);
    assert( proglen>0 );
  }
  
  {
    /* get offset table for embeded data */
    SV* sv_hvref_table = get_sv("Unicode::Japanese::PurePerl::TABLE",0);
    assert(sv_hvref_table!=NULL);
    assert(SvROK(sv_hvref_table));
    hv_table = (HV*)SvRV(sv_hvref_table);
    assert(hv_table!=NULL);
    assert(SvTYPE((SV*)hv_table)==SVt_PVHV);
  }
  
  {
    int dummy;
    struct
    {
      const char*      filename;
      const UJ_UINT8** data_ptr;
      int*             size_ptr;
    } *ptr, embeded[] = 
    {
      /* sjis<=>utf-8 */
      { "jcode/s2u.dat", &g_s2u_table, &dummy, },
      { "jcode/u2s.dat", &g_u2s_table, &dummy, },
      /* i-mode */
      { "jcode/emoji2/eu2i.dat", (const UJ_UINT8**)&g_eu2i1_table, &g_eu2i1_size, },
      { "jcode/emoji2/ei2u.dat", (const UJ_UINT8**)&g_ei2u1_table, &g_ei2u1_size, },
      { "jcode/emoji2/eu2i2.dat",(const UJ_UINT8**)&g_eu2i2_table, &g_eu2i2_size, },
      { "jcode/emoji2/ei2u2.dat",(const UJ_UINT8**)&g_ei2u2_table, &g_ei2u2_size, },
      /* vodafone */
      { "jcode/emoji2/eu2j.dat", (const UJ_UINT8**)&g_eu2j1_table, &g_eu2j1_size, },
      { "jcode/emoji2/ej2u.dat", (const UJ_UINT8**)&g_ej2u1_table, &g_ej2u1_size, },
      { "jcode/emoji2/eu2j2.dat",(const UJ_UINT8**)&g_eu2j2_table, &g_eu2j2_size, },
      { "jcode/emoji2/ej2u2.dat",(const UJ_UINT8**)&g_ej2u2_table, &g_ej2u2_size, },
      /* dot-i */
      { "jcode/emoji2/eu2d.dat", (const UJ_UINT8**)&g_eu2d_table,  &g_eu2d_size, },
      { "jcode/emoji2/ed2u.dat", (const UJ_UINT8**)&g_ed2u_table,  &g_ed2u_size, },
      /* au */
      { "jcode/emoji2/eu2a.dat", (const UJ_UINT8**)&g_eu2a1_table, &g_eu2a1_size, },
      { "jcode/emoji2/ea2u.dat", (const UJ_UINT8**)&g_ea2u1_table, &g_ea2u1_size, },
      { "jcode/emoji2/eu2a2.dat",(const UJ_UINT8**)&g_eu2a2_table, &g_eu2a2_size, },
      { "jcode/emoji2/ea2u2.dat",(const UJ_UINT8**)&g_ea2u2_table, &g_ea2u2_size, },
      /* au(s) */
      { "jcode/emoji2/eu2as.dat", (const UJ_UINT8**)&g_eu2a1s_table, &g_eu2a1s_size, },
      { "jcode/emoji2/ea2us.dat", (const UJ_UINT8**)&g_ea2u1s_table, &g_ea2u1s_size, },
      { "jcode/emoji2/eu2a2s.dat",(const UJ_UINT8**)&g_eu2a2s_table, &g_eu2a2s_size, },
      { "jcode/emoji2/ea2u2s.dat",(const UJ_UINT8**)&g_ea2u2s_table, &g_ea2u2s_size, },
      /* terminator. */
      {
        NULL, NULL, NULL, 
      },
    };
    for( ptr=embeded; ptr->filename!=NULL; ++ptr )
    {
      SV** sv_entryref;
      HV*  hv_entry;
      SV** sv_offset;
      SV** sv_length;
      IV offset;
      IV length;
      
      /* sv_entryref = $TABLE->{$filename} */
      sv_entryref = hv_fetch(hv_table,ptr->filename, strlen(ptr->filename), 0);
      if( sv_entryref==NULL )
      {
        croak("Unicode::Japanese#do_memmap, embedded file [%s] not found",ptr->filename);
      }
      /* assert(isa(sv_entryref,"HASH")) */
      hv_entry = SvROK(*sv_entryref) ? (HV*)SvRV(*sv_entryref) : NULL;
      if( hv_entry!=NULL && SvTYPE((SV*)hv_entry)!=SVt_PVHV )
      {
        croak("Unicode::Japanese#do_memmap, embedded file entry [%s] is not hashref",ptr->filename);
      }
      /* sv_offset = $hv_entry{"offset"} */
      /* sv_length = $hv_entry{"length"} */
      sv_offset = hv_fetch(hv_entry,"offset",6,0);
      sv_length = hv_fetch(hv_entry,"length",6,0);
      if( sv_offset==NULL )
      {
        croak("Unicode::Japanese#do_memmap, no offset for embedded file entry [%s]",ptr->filename);
      }
      if( sv_length==NULL )
      {
        croak("Unicode::Japanese#do_memmap, no length for embedded file entry [%s]",ptr->filename);
      }
      offset = SvIV(*sv_offset);
      length = SvIV(*sv_length);
      *ptr->data_ptr = (const UJ_UINT8*)mmap_pmfile + proglen + headlen + offset;
      *ptr->size_ptr = length;
      /* printf("[%s] offset: %d, length: %d\n", ptr->filename, offset, length); */
    }
  }
  return;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
