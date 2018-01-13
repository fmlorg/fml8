/* ----------------------------------------------------------------------------
 * decode_term.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

/*
usage:
declare_call_handler(proc)
{
  const char* str_ptr;
  const char* re_ptr;
  void* str_xbuf;
  void* re_xbuf;
  int str_len;
  int re_len;
  int rx_flags;
  
  DEBUG(printf("decode: str\r\n"));
  str_ptr = _decode_string(&buff, buff_end, &str_len, &str_xbuf);
  if( str_ptr!=NULL )
  {
    DEBUG(printf("str = [%.*s] (%d)\r\n", str_len, str_ptr, str_len));
  }else
  {
    return (int)ERL_DRV_ERROR_GENERAL;
  }
  
  DEBUG(printf("decode: re\r\n"));
  re_ptr = _decode_string(&buff, buff_end, &re_len, &re_xbuf);
  if( re_ptr!=NULL )
  {
    DEBUG(printf("re  = [%.*s] (%d)\r\n", re_len, re_ptr, re_len));
  }else
  {
    xbuf_free(str_xbuf);
    return (int)ERL_DRV_ERROR_GENERAL;
  }
  ...
  xbuf_free(str_xbuf);
  xbuf_free(re_xbuf);
}
*/

typedef struct {
	unsigned char* wptr;
	const unsigned char* end;
	int req;
	unsigned char data[1];
} xbuff_t;

static int _decode_string_heavy(const unsigned char* in, const unsigned char* in_end, xbuff_t** pxbuff);

/* ----------------------------------------------------------------------------
 * _decode_string(&in, end, &len, &xbuff).
 * term_to_binary()でpackされた文字列のデコード.
 * 外部形式 binary/atom/string/list をサポート.
 * inが開始位置, endがデータの終端.
 * デコードに成功すると,
 * - 復帰値: 文字列へのポインタ(NULL終端なし)
 * - len:    文字列の長さ(バイト長)
 * - xbuff:   alloc情報
 * の3つの情報を返す.
 * デコードに失敗した場合は NULL を返す.
 * 文字列は入力データを直接参照する場合もあるし,
 * 別途確保した領域を使うこともある.
 * xbuffにその情報を記録している.
 * 使い終わったら xbuff_free(xbuff) で解放すること.
 * ------------------------------------------------------------------------- */
static const char* _decode_string(const unsigned char** pbuff, const unsigned char* buff_end, int* plen, void** pxbuff)
{
	const unsigned char* buff = *pbuff;
	if( buff+1<=buff_end )
	{
	}else
	{
		*pxbuff = NULL;
		return NULL;
	}
	
	switch( buff[0] )
	{
	case BINARY_EXT:
		*pxbuff = NULL;
		DEBUG(printf("  decode from binary\r\n"));
		if( buff+4<=buff_end )
		{
			const int len = (buff[1]<<24) + (buff[2]<<16) + (buff[3]<<8) + buff[4];
			DEBUG(printf("  len = %d\n", len));
			DEBUG(printf("  str = [%.*s]\n", len, buff+5));
			*plen = len;
			*pbuff = buff+5+len;
			return (char*)buff+5;
		}else
		{
			return NULL;
		}
	case ATOM_EXT:
	case STRING_EXT:
		*pxbuff = NULL;
		DEBUG(printf("  decode from string/atom\r\n"));
		if( buff+3<=buff_end )
		{
			const int len = (buff[1]<<8) + buff[2];
			DEBUG(printf("  len = %d\n", len));
			DEBUG(printf("  str = [%.*s]\n", len, buff+3));
			*plen = len;
			*pbuff = buff+3+len;
			return (char*)buff+3;
		}else
		{
			return NULL;
		}
	case NIL_EXT:
		*pxbuff = NULL;
		*plen = 0;
		*pbuff = buff+1;
		return (char*)buff+1;
	case LIST_EXT:
		{
			const int len = (buff[1]<<24) + (buff[2]<<16) + (buff[3]<<8) + buff[4];
			xbuff_t* xbuff = driver_alloc(sizeof(*xbuff)+len-1);
			int ret;
			xbuff->wptr = &xbuff->data[0];
			xbuff->end  = xbuff->wptr + len;
			xbuff->req  = 0;
			DEBUG(printf("HEAVY: len=%d\n", len));
			ret = _decode_string_heavy(buff, buff_end, &xbuff);
			DEBUG(printf("heavy : %d\n", ret));
			*pxbuff = xbuff;
			if( ret!=-1 )
			{
				*pbuff = buff+ret;
				*plen = xbuff->wptr-xbuff->data;
				DEBUG(printf("- [%.*s]\n", *plen, xbuff->data));
				return (char*)xbuff->data;
			}else
			{
				return NULL;
			}
		}
	}
	return NULL;
}

static void xbuff_expect(xbuff_t** pxbuff, int req)
{
	(*pxbuff)->req += req;
	return;
}

static xbuff_t* xbuff_extend(xbuff_t** pxbuff)
{
	xbuff_t* xbuff = *pxbuff;
	unsigned char* old_buf;
	xbuff_t* new_xbuff;
	int req, siz;
	old_buf = (void*)xbuff;
	req = xbuff->req!=0 ? xbuff->req : 32;
	siz = ((xbuff->end - (unsigned char*)xbuff) + req + 7) & ~7;
	new_xbuff = driver_realloc(xbuff, siz);
	if( new_xbuff!=NULL )
	{
		new_xbuff->wptr = new_xbuff->wptr + ((unsigned char*)new_xbuff - old_buf);
		new_xbuff->end  = (unsigned char*)new_xbuff + siz;
		new_xbuff->req  = 0;
		*pxbuff = new_xbuff;
		return new_xbuff;
	}else
	{
		return NULL;
	}
}

static int _decode_string_heavy(const unsigned char* in, const unsigned char* in_end, xbuff_t** pxbuff)
{
	if( in>=in_end )
	{
		return -1;
	}
	switch( *in )
	{
	case NIL_EXT:
		DEBUG(printf("heavy: nil\n"));
		return 1;
	case SMALL_INTEGER_EXT:
		DEBUG(printf("heavy: small_int\n"));
		if( in+2<in_end )
		{
			xbuff_t* xbuff = *pxbuff;
			if( xbuff->wptr<xbuff->end ){
				*(*pxbuff)->wptr++ = in[1];
			}else if( xbuff_extend(pxbuff) ){
				*(*pxbuff)->wptr++ = in[1];
			}else{
				return -1;
			}
			return 2;
		}else
		{
			return -1;
		}
	case STRING_EXT:
		DEBUG(printf("heavy: string\n"));
		if( in+3<in_end )
		{
			const int len = (in[1]<<8) + in[2];
			xbuff_expect(pxbuff, len);
			if( (*pxbuff)->wptr+len<(*pxbuff)->end )
			{
				memcpy((*pxbuff)->wptr, in+3, len);
			}else if( xbuff_extend(pxbuff) )
			{
				memcpy((*pxbuff)->wptr, in+3, len);
			}else{
				return -1;
			}
			DEBUG(printf(".. %d\n", len+3));
			(*pxbuff)->wptr += len;
			return len+3;
		}else
		{
			return -1;
		}
	case BINARY_EXT:
		DEBUG(printf("heavy: binary\n"));
		if( in+5<in_end )
		{
			const int len = (in[1]<<24) + (in[2]<<16) + (in[3]<<8) + in[4];
			xbuff_expect(pxbuff, len);
			if( (*pxbuff)->wptr+len<(*pxbuff)->end )
			{
				memcpy((*pxbuff)->wptr, in+5, len);
			}else if( xbuff_extend(pxbuff) )
			{
				memcpy((*pxbuff)->wptr, in+5, len);
			}else{
				return -1;
			}
			DEBUG(printf(".. %d\n", len+3));
			(*pxbuff)->wptr += len;
			return len+5;
		}else
		{
			return -1;
		}
	case LIST_EXT:
		DEBUG(printf("heavy: list\n"));
		if( in+5<in_end )
		{
			const int len = (in[1]<<24) + (in[2]<<16) + (in[3]<<8) + in[4];
			int total_step;
			int i;
			xbuff_expect(pxbuff, len);
			total_step = 5;
			in += 5;
			for( i=0; i<len; ++i )
			{
				int step = _decode_string_heavy(in, in_end, pxbuff);
				if( step==-1 )
				{
					return -1;
				}
				in += step;
				total_step += step;
			}
			if( in<in_end && *in==NIL_EXT )
			{
				return total_step+1;
			}
			return -1;
		}else
		{
			return -1;
		}
	default:
		DEBUG(printf("heavy: unknown %c (%d)\n", *in, *in));
		return -1;
	}
}

#define xbuf_free(var) if(var==NULL){}else{driver_free(var);}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
