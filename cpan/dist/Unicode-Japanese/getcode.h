
#ifndef GETCODE_H
#define GETCODE_H

// $Id: getcode.h,v 1.1 2001/11/30 13:46:26 hio Exp $

#ifdef TEST
#define DECL_MAP_MODE(name,num) \
  extern const char* mode_##name[num]
#else
#define DECL_MAP_MODE(name,num)
#endif

#define DECL_MAP_TABLE(name,num) \
  extern const unsigned char map_##name[num][256]

#define DECL_MAP(name,num) DECL_MAP_MODE(name,num); DECL_MAP_TABLE(name,num)

DECL_MAP(ascii,1);
DECL_MAP(eucjp,5);
DECL_MAP(sjis,2);
DECL_MAP(utf8,6);
DECL_MAP(jis,10);
DECL_MAP(utf32_be,4);
DECL_MAP(utf32_le,4);
DECL_MAP(sjis_jsky,5);
DECL_MAP(sjis_imode,4);
DECL_MAP(sjis_doti,7);

#define map_invalid 0x7f

#endif
