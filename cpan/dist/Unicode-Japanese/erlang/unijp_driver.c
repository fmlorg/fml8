/* ----------------------------------------------------------------------------
 * unijp_driver.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2008 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include "unijp.h"

#include <stdio.h>
#include <erl_driver.h>
#include <erl_interface.h>
#include <ei.h>

#undef assert
#include <assert.h>
#include <string.h>

#if 0
#define DEBUG(cmd) cmd
#else
#define DEBUG(cmd)
#endif

#define VERSION_MAGIC   ((char)131)
#define SMALL_INTEGER_EXT 'a' /* 97 */
#define INTEGER_EXT       'b' /* 98 */
#define ATOM_EXT        'd' /* 100 */
#define SMALL_TUPLE_EXT 'h' /* 104 */
#define NIL_EXT         'j' /* 106 */
#define STRING_EXT      'k' /* 107 */
#define LIST_EXT        'l' /* 108 */
#define BINARY_EXT      'm' /* 109 */

#include "decode_term.c"

#define PORT_VERSION_STR   1
#define PORT_VERSION_TUPLE 2
#define PORT_CONV_3        3

/* ----------------------------------------------------------------------------
 * Declarations.
 * ------------------------------------------------------------------------- */
typedef struct
{
	ErlDrvPort port;
} my_data;

static ETERM* atom_ok;
static ETERM* atom_error;

/* ----------------------------------------------------------------------------
 * port_call handlers.
 * declare_call_handler(name).
 * invoke_call_handler(name).
 * ------------------------------------------------------------------------- */
#define declare_call_handler(name) \
	static int unijp_drv_call_##name(my_data* d, unsigned int command, unsigned char *buff_in, int buff_len, char **rbuf, int rlen, unsigned int *flags)
#define invoke_call_handler(name) \
	unijp_drv_call_##name(d, command, (unsigned char*)buff, bufflen, rbuf, rlen, flags)

declare_call_handler(version_str);
declare_call_handler(version_tuple);
declare_call_handler(conv_3);



/* ----------------------------------------------------------------------------
 * my_erl_init.
 * ------------------------------------------------------------------------- */
static void my_erl_init(void *hp, long heap_size)
{   
	void erl_init_marshal(void);
	void ei_init_resolve(void);
	erl_init_malloc(hp, heap_size);
	erl_init_marshal();
	ei_init_resolve();
}

/* ----------------------------------------------------------------------------
 * unijp allocator.
 * ------------------------------------------------------------------------- */
void* uja_alloc(void* baton, uj_size_t size)
{
  return driver_alloc(size);
}
void* uja_realloc(void* baton, void* ptr, uj_size_t size)
{
  return driver_realloc(ptr, size);
}
void uja_free(void* baton, void* ptr)
{
  return driver_free(ptr);
}
/* ----------------------------------------------------------------------------
 * unijp_drv_init @ lid handler.
 * ------------------------------------------------------------------------- */
static int unijp_drv_init(void)
{
	DEBUG(printf("erl_init...\r\n"));
	my_erl_init(NULL,0);
	atom_ok      = erl_mk_atom("ok");
	atom_error   = erl_mk_atom("error");

	static const uj_alloc_t my_uj_alloc = {
		UJ_ALLOC_MAGIC,
		NULL,
		&uja_alloc,
		&uja_realloc,
		&uja_free,
	};
	_uj_default_alloc = &my_uj_alloc;

	return 0;
}

/* ----------------------------------------------------------------------------
 * unijp_drv_start @ lid handler.
 * ------------------------------------------------------------------------- */
static ErlDrvData unijp_drv_start(ErlDrvPort port, char *buff)
{
	my_data* d;
	DEBUG(printf("drv_start %ld.\n", (long)port));
	d = driver_alloc(sizeof(my_data));
	d->port = port;
	return (ErlDrvData)d;
}

/* ----------------------------------------------------------------------------
 * unijp_drv_stop @ lid handler.
 * ------------------------------------------------------------------------- */
static void unijp_drv_stop(ErlDrvData handle)
{
	DEBUG(printf("drv_stop.\r\n"));
	driver_free((char*)handle);
	return;
}

/* ----------------------------------------------------------------------------
 * unijp_drv_finish @ lid handler.
 * ------------------------------------------------------------------------- */
static void unijp_drv_finish(void)
{
	DEBUG(printf("erl_finish.\r\n"));
	return;
}

/* ----------------------------------------------------------------------------
 * unijp_drv_call @ lid handler.
 * ------------------------------------------------------------------------- */

int unijp_drv_call(ErlDrvData handle, unsigned int command, char *buff, int bufflen, char **rbuf, int rlen, unsigned int *flags)
{
	my_data* d = (my_data*)handle;
	DEBUG(printf("drv_call:%u.\n", command));
	DEBUG({int i;for(i=0;i<bufflen;++i){printf("%d: %c (%d)\n",i,buff[i],buff[i]);}});
	switch(command)
	{
	case PORT_VERSION_STR:   return invoke_call_handler(version_str);
	case PORT_VERSION_TUPLE: return invoke_call_handler(version_tuple);
	case PORT_CONV_3:        return invoke_call_handler(conv_3);
	default:
		return (int)ERL_DRV_ERROR_GENERAL;
	}
}

/* ----------------------------------------------------------------------------
 * unijp_drv_call_version_str @ drv:call handler.
 * ------------------------------------------------------------------------- */
declare_call_handler(version_str)
/*
  [unijp_drv_call_version_str]
  my_data *       d;
  unsigned int    command;
  unsigned char * buff_in;
  int             buff_len;
  char **         rbuf;
  int             rlen;
  unsigned int *  flags;
*/
{
	ETERM* out_term;
	ETERM* out_tuple[2];
	int out_len;
	const char* version_str;

	/* argument check. */
	{
		static const char prefix[2] = {
			VERSION_MAGIC, NIL_EXT,
		};
		const unsigned char* buff = buff_in;
		const unsigned char* buff_end = buff+buff_len;
		DEBUG(printf("drv_call:version_str.\n"));
		if( buff_len >= sizeof(prefix) && memcmp(buff, prefix, sizeof(prefix))==0 )
		{
			buff += sizeof(prefix);
		}else
		{
			DEBUG(printf("len:%d, %c\n", buff_len, buff[0]));
			return (int)ERL_DRV_ERROR_GENERAL;
		}

		if( buff==buff_end )
		{
		}else
		{
			return (int)ERL_DRV_ERROR_GENERAL;
		}
	}

	version_str = UNIJP_VERSION_STRING;

	out_tuple[0] = atom_ok;
	out_tuple[1] = erl_mk_estring(version_str, strlen(version_str));

	out_term = erl_mk_tuple(out_tuple, 2);
	out_len = erl_term_len(out_term);
	if( rlen<out_len )
	{
		*rbuf = driver_alloc(out_len);
	}
	erl_encode(out_term, (unsigned char*)*rbuf);

	erl_free_term(out_term);
	erl_free_term(out_tuple[1]);

	DEBUG(printf("out_len = %d\r\n", out_len));
	return out_len;
}

/* ----------------------------------------------------------------------------
 * unijp_drv_call_version_tuple @ drv:call handler.
 * ------------------------------------------------------------------------- */
declare_call_handler(version_tuple)
/*
  [unijp_drv_call_version_tuple]
  my_data *       d;
  unsigned int    command;
  unsigned char * buff_in;
  int             buff_len;
  char **         rbuf;
  int             rlen;
  unsigned int *  flags;
*/
{
	int out_len;
	int ver_major, ver_minor, ver_patch;

	/* argument check. */
	{
		static const char prefix[2] = {
			VERSION_MAGIC, NIL_EXT,
		};
		const unsigned char* buff = buff_in;
		const unsigned char* buff_end = buff+buff_len;
		DEBUG(printf("drv_call:version_tuple.\n"));
		if( buff_len >= sizeof(prefix) && memcmp(buff, prefix, sizeof(prefix))==0 )
		{
			buff += sizeof(prefix);
		}else
		{
			DEBUG(printf("len:%d, %c\n", buff_len, buff[0]));
			return (int)ERL_DRV_ERROR_GENERAL;
		}

		if( buff==buff_end )
		{
		}else
		{
			return (int)ERL_DRV_ERROR_GENERAL;
		}
	}

	/* body. */
	ver_major = UNIJP_VERSION_MAJOR;
	ver_minor = UNIJP_VERSION_MINOR;
	ver_patch = UNIJP_VERSION_PATCH;

	{
		ETERM* out_term;
		ETERM* out_tuple[2];
		ETERM* ver_tuple[3];
		ver_tuple[0] = erl_mk_int(ver_major);
		ver_tuple[1] = erl_mk_int(ver_minor);
		ver_tuple[2] = erl_mk_int(ver_patch);
		out_tuple[0] = atom_ok;
		out_tuple[1] = erl_mk_tuple(ver_tuple, 3);

		out_term = erl_mk_tuple(out_tuple, 2);
		out_len = erl_term_len(out_term);
		if( rlen<out_len )
		{
			*rbuf = driver_alloc(out_len);
		}
		erl_encode(out_term, (unsigned char*)*rbuf);

		erl_free_term(out_term);
		erl_free_compound(out_tuple[1]);

		DEBUG(printf("out_len = %d\r\n", out_len));
	}
	return out_len;
}

/* ----------------------------------------------------------------------------
 * unijp_drv_call_conv_3 @ drv:call handler.
 * ------------------------------------------------------------------------- */
declare_call_handler(conv_3)
/*
  [unijp_drv_call_conv_3]
  my_data *       d;
  unsigned int    command;
  unsigned char * buff_in;
  int             buff_len;
  char **         rbuf;
  int             rlen;
  unsigned int *  flags;
*/
{
	ETERM* out_term;
	ETERM* out_tuple[2];
	int out_len;
	const char* from_ptr;
	int         from_len;
	void*       from_xbuf;
	const char* to_ptr;
	int         to_len;
	void*       to_xbuf;
	const char* str_ptr;
	int         str_len;
	void*       str_xbuf;

	uj_uint8* ret;
	uj_size_t ret_len;

	/* argument check. */
	{
		static const char prefix[3] = {
			VERSION_MAGIC, SMALL_TUPLE_EXT, 3,
		};
		const unsigned char* buff = buff_in;
		const unsigned char* buff_end = buff+buff_len;

		DEBUG(printf("drv_call:conv_3.\n"));
		if( buff_len >= sizeof(prefix) && memcmp(buff, prefix, sizeof(prefix))==0 )
		{
			buff += sizeof(prefix);
		}else
		{
			DEBUG(printf("len:%d, %c\n", buff_len, buff[0]));
			return (int)ERL_DRV_ERROR_GENERAL;
		}

		DEBUG(printf("decode: from\r\n"));
		from_ptr = _decode_string(&buff, buff_end, &from_len, &from_xbuf);
		if( from_ptr!=NULL )
		{
			DEBUG(printf("from = [%.*s] (%d)\r\n", from_len, from_ptr, from_len));
		}else
		{
			return (int)ERL_DRV_ERROR_GENERAL;
		}

		DEBUG(printf("decode: to\r\n"));
		to_ptr = _decode_string(&buff, buff_end, &to_len, &to_xbuf);
		if( to_ptr!=NULL )
		{
			DEBUG(printf("to = [%.*s] (%d)\r\n", to_len, to_ptr, to_len));
		}else
		{
			return (int)ERL_DRV_ERROR_GENERAL;
		}

		DEBUG(printf("decode: str\r\n"));
		str_ptr = _decode_string(&buff, buff_end, &str_len, &str_xbuf);
		if( str_ptr!=NULL )
		{
			DEBUG(printf("str = [%.*s] (%d)\r\n", str_len, str_ptr, str_len));
		}else
		{
			return (int)ERL_DRV_ERROR_GENERAL;
		}

		if( buff==buff_end )
		{
		}else
		{
			return (int)ERL_DRV_ERROR_GENERAL;
		}
	}

	/* body. */
	{
		uj_charcode_t icode;
		uj_charcode_t ocode;
		unijp_t* uj;
		icode = uj_charcode_parse_n(from_ptr, from_len);
		ocode = uj_charcode_parse_n(to_ptr, to_len);
		if( icode==ujc_undefined )
		{
			DEBUG(printf("icode invalid: [%.*s]\n", from_len, from_ptr));
			return (int)ERL_DRV_ERROR_GENERAL;
		}
		if( ocode==ujc_undefined )
		{
			DEBUG(printf("ocode invalid: [%.*s]\n", to_len, to_ptr));
			return (int)ERL_DRV_ERROR_GENERAL;
		}
		uj = uj_new((uj_uint8*)str_ptr, str_len, icode);
		if( uj==NULL )
		{
			DEBUG(printf("uj_new failed: %s\n", strerror(errno)));
			return (int)ERL_DRV_ERROR_GENERAL;
		}
		ret = uj_conv(uj, ocode, &ret_len);
		uj_delete(uj);
		if( ret==NULL )
		{
			DEBUG(printf("uj_conv failed: %s\n", strerror(errno)));
			return (int)ERL_DRV_ERROR_GENERAL;
		}
		DEBUG(printf("conv success: ret_len=%d.\n", ret_len));
	}

	out_tuple[0] = atom_ok;
	out_tuple[1] = erl_mk_estring((char*)ret, ret_len);

	out_term = erl_mk_tuple(out_tuple, 2);
	out_len = erl_term_len(out_term);
	if( rlen<out_len )
	{
		*rbuf = driver_alloc(out_len);
	}
	erl_encode(out_term, (unsigned char*)*rbuf);

	erl_free_term(out_term);
	erl_free_term(out_tuple[1]);
	uja_free(NULL, ret);

	DEBUG(printf("out_len = %d\r\n", out_len));
	return out_len;
}

/* ----------------------------------------------------------------------------
 * @ driver entry.
 * ------------------------------------------------------------------------- */
ErlDrvEntry unijp_driver_entry = {
	&unijp_drv_init,   /* F_PTR init, N/A */
	&unijp_drv_start,  /* L_PTR start, called when port is opened */
	&unijp_drv_stop,   /* F_PTR stop, called when port is closed */
	NULL,               /* F_PTR output, called when erlang has sent
	                       data to the port */
	NULL,               /* F_PTR ready_input, 
	                       called when input descriptor ready to read*/
	NULL,               /* F_PTR ready_output, 
	                       called when output descriptor ready to write */
	"unijp_driver",       /* char *driver_name, the argument to open_port */
	&unijp_drv_finish, /* F_PTR finish, called when unloaded */
	NULL,               /* ??? handle */
	NULL,               /* F_PTR control, port_command callback */
	NULL,               /* F_PTR timeout, reserved */
	(void(*)(ErlDrvData,ErlIOVec*))NULL, /* F_PTR outputv, reserved */
	
	/* new feature. */
	(void(*)(ErlDrvData,ErlDrvThreadData))NULL, /* ready_async */
	(void(*)(ErlDrvData drv_data)) NULL,        /* ??? flush */
	&unijp_drv_call,                           /* call */
	(void(*)(ErlDrvData,ErlDrvEvent,ErlDrvEventData))NULL, /* event */
	ERL_DRV_EXTENDED_MARKER,           /* extended_marker */
	ERL_DRV_EXTENDED_MAJOR_VERSION,    /* major_version */
	ERL_DRV_EXTENDED_MINOR_VERSION,    /* minor_version */
	ERL_DRV_FLAG_USE_PORT_LOCKING,     /* driver_flags */
	0, /* handle */
	0  /* process_exit */
};

DRIVER_INIT(unijp_driver) /* must match name in driver_entry */
{
    DEBUG(printf("driver_init ...\n" ));
    return &unijp_driver_entry;
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
