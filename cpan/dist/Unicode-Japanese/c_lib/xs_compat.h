/* ----------------------------------------------------------------------------
 * xs_compat.h
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */
#ifndef UNIJP_XS_COMPAT_H
#define UNIJP_XS_COMPAT_H

extern uj_conv_t* _uj_conv_new_strn(const uj_alloc_t* alloc, const char* str, uj_size_t len);
extern uj_conv_t* _uj_conv_clone(const uj_conv_t* conv);

extern const uj_conv_t _uj_xs_conv_undef;
extern uj_size_t _uj_xs_PL_na;
extern void _uj_xs_SV_Buf_append_ch(uj_conv_t* conv, int ch);
extern void _uj_xs_SV_Buf_append_ch2(uj_conv_t* conv, int ch);
extern void _uj_xs_SV_Buf_append_ch3(uj_conv_t* conv, int ch);
extern void _uj_xs_SV_Buf_append_ch4(uj_conv_t* conv, int ch);
extern void _uj_xs_SV_Buf_append_mem(uj_conv_t* conv, const uj_uint8* s, int len);
extern void _uj_xs_SV_Buf_append_entityref(uj_conv_t* conv, int ch);
extern uj_conv_t* _uj_xs_SV_Buf_getSv(const uj_conv_t* conv);


#define UNICODE__JAPANESE_H__

#ifndef EXTERN_C
#ifdef __cplusplus
#define extern "C"
#else
#define EXTERN_C
#endif
#endif

#define STRLEN uj_size_t

#define UJ_UINT32 uj_uint32
#define UJ_UINT16 uj_uint16
#define UJ_UINT8  uj_uint8

#define SV uj_conv_t
#define SV_Buf uj_conv_t
#define SV_Buf_init(p_var, len) (\
  (p_var)->alloc       = (sv_str)->alloc, \
  (p_var)->buf         = _uj_alloc((sv_str)->alloc,len), \
  (p_var)->buf_len     = 0, \
  (p_var)->buf_bufsize = (len) \
  )

#define PL_sv_undef        (_uj_xs_conv_undef)
#define newSVpvn(str, len) _uj_conv_new_strn(_uj_default_alloc,str,len)
#define newSVsv(p_var)     _uj_conv_clone(p_var)

#define SvPV(var,len) ((len)=(var)->buf_len,(var)->buf)
#define sv_len(var)   ((var)->buf_len)
#define SvGMAGICAL(sv) (0)
#define mg_get(sv)     ((void)0)
#define SvOK(sv)       ((sv) != &PL_sv_undef)

#define PL_na                              _uj_xs_PL_na
#define SV_Buf_append_ch(p_var,ch)         _uj_xs_SV_Buf_append_ch(p_var, ch)
#define SV_Buf_append_ch2(p_var,ch)        _uj_xs_SV_Buf_append_ch2(p_var, ch)
#define SV_Buf_append_ch3(p_var,ch)        _uj_xs_SV_Buf_append_ch3(p_var, ch)
#define SV_Buf_append_ch4(p_var,ch)        _uj_xs_SV_Buf_append_ch4(p_var, ch)
#define SV_Buf_append_mem(p_var,ptr,len)   _uj_xs_SV_Buf_append_mem(p_var, ptr, len)
#define SV_Buf_append_entityref(p_var,ch)  _uj_xs_SV_Buf_append_entityref(p_var, ch)
#define SV_Buf_setLength(p_var)            ((void)0)
#define SV_Buf_getSv(p_var)                (*__out=*p_var,__out)

#endif /* !defined(UNIJP_XS_COMPAT_H) */
/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
