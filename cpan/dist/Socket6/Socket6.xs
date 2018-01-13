/*
 * Socket6.xs
 * $Id: Socket6.xs 662 2016-03-22 16:03:49Z ume $
 *
 * Copyright (C) 2000-2016 Hajimu UMEMOTO <ume@mahoroba.org>.
 * All rights reserved.
 *
 * This moduled is besed on perl5.005_55-v6-19990721 written by KAME
 * Project.
 *
 * Copyright (C) 1995, 1996, 1997, 1998, and 1999 WIDE Project.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the project nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifdef WIN32

#define	WINVER		0x0501
#include <winsock2.h>
#include <ws2tcpip.h>
#ifndef NI_NUMERICSERV
#error Microsoft Platform SDK (Aug. 2001) or later required.
#endif
const struct in6_addr in6addr_any = IN6ADDR_ANY_INIT;
const struct in6_addr in6addr_loopback = IN6ADDR_LOOPBACK_INIT;
#define	WSA_DECLARE					\
	WSADATA wsaData;				\
	int wsa = 0
#define	WSA_STARTUP()					\
	wsa = WSAStartup(MAKEWORD(2,2), &wsaData)
#define	WSA_CLEANUP()					\
	if (!wsa) WSACleanup()

#else /* WIN32 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#ifdef __KAME__
# include <sys/param.h>
# include <net/route.h>
# if defined(__FreeBSD__) && __FreeBSD_version >= 700048
#  include <netipsec/ipsec.h>
# elif !defined(__OpenBSD__)
#  include <netinet6/ipsec.h>
# endif
#endif
#include <netdb.h>
#define	WSA_DECLARE
#define	WSA_STARTUP()
#define	WSA_CLEANUP()

#endif /* WIN32 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "config.h"

#if defined(HAVE_INET_NTOP) && !defined(CAN_INET_NTOP)
#undef HAVE_INET_NTOP
#endif

#ifndef HAVE_GETADDRINFO
#include "getaddrinfo.c"
#define	NI_MAXHOST		1025
#define	NI_MAXSERV		32
#define	HAVE_GETADDRINFO	1
#endif
#ifndef	HAVE_GETNAMEINFO
#include "getnameinfo.c"
#define	HAVE_GETNAMEINFO	1
#endif

#ifndef HAVE_INET_NTOP
#include "inet_ntop.c"
#define	HAVE_INET_NTOP		1
#endif
#ifndef HAVE_INET_PTON
#include "inet_pton.c"
#define	HAVE_INET_PTON		1
#endif

#ifndef HAVE_PL_SV_UNDEF
#define	PL_sv_undef		sv_undef
#endif

static int
not_here(char *s)
{
    croak("Socket6::%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "AF_INET6"))
#ifdef AF_INET6
	    return AF_INET6;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_ADDRCONFIG"))
#ifdef AI_ADDRCONFIG
	    return AI_ADDRCONFIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_ALL"))
#ifdef AI_ALL
	    return AI_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_CANONNAME"))
#ifdef AI_CANONNAME
	    return AI_CANONNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_NUMERICHOST"))
#ifdef AI_NUMERICHOST
	    return AI_NUMERICHOST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_NUMERICSERV"))
#ifdef AI_NUMERICSERV
	    return AI_NUMERICSERV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_DEFAULT"))
#ifdef AI_DEFAULT
	    return AI_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_MASK"))
#ifdef AI_MASK
	    return AI_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_PASSIVE"))
#ifdef AI_PASSIVE
	    return AI_PASSIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_V4MAPPED"))
#ifdef AI_V4MAPPED
	    return AI_V4MAPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AI_V4MAPPED_CFG"))
#ifdef AI_V4MAPPED_CFG
	    return AI_V4MAPPED_CFG;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "EAI_ADDRFAMILY"))
#ifdef EAI_ADDRFAMILY
	    return EAI_ADDRFAMILY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_AGAIN"))
#ifdef EAI_AGAIN
	    return EAI_AGAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_BADFLAGS"))
#ifdef EAI_BADFLAGS
	    return EAI_BADFLAGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_FAIL"))
#ifdef EAI_FAIL
	    return EAI_FAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_FAMILY"))
#ifdef EAI_FAMILY
	    return EAI_FAMILY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_MEMORY"))
#ifdef EAI_MEMORY
	    return EAI_MEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_NODATA"))
#ifdef EAI_NODATA
	    return EAI_NODATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_NONAME"))
#ifdef EAI_NONAME
	    return EAI_NONAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_SERVICE"))
#ifdef EAI_SERVICE
	    return EAI_SERVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_SOCKTYPE"))
#ifdef EAI_SOCKTYPE
	    return EAI_SOCKTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_SYSTEM"))
#ifdef EAI_SYSTEM
	    return EAI_SYSTEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_BADHINTS"))
#ifdef EAI_BADHINTS
	    return EAI_BADHINTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EAI_PROTOCOL"))
#ifdef EAI_PROTOCOL
	    return EAI_PROTOCOL;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	if (strEQ(name, "IP_AUTH_TRANS_LEVEL"))
#ifdef IP_AUTH_TRANS_LEVEL
	    return IP_AUTH_TRANS_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IP_AUTH_NETWORK_LEVEL"))
#ifdef IP_AUTH_NETWORK_LEVEL
	    return IP_AUTH_NETWORK_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IP_ESP_TRANS_LEVEL"))
#ifdef IP_ESP_TRANS_LEVEL
	    return IP_ESP_TRANS_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IP_EPS_NETWORK_LEVEL"))
#ifdef IP_EPS_NETWORK_LEVEL
	    return IP_EPS_NETWORK_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPPROTO_IP"))
#ifdef IPPROTO_IP
	    return IPPROTO_IP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPPROTO_IPV6"))
#ifdef IPPROTO_IPV6
	    return IPPROTO_IPV6;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_AVAIL"))
#ifdef IPSEC_LEVEL_AVAIL
	    return IPSEC_LEVEL_AVAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_BYPASS"))
#ifdef IPSEC_LEVEL_BYPASS
	    return IPSEC_LEVEL_BYPASS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_DEFAULT"))
#ifdef IPSEC_LEVEL_DEFAULT
	    return IPSEC_LEVEL_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_NONE"))
#ifdef IPSEC_LEVEL_NONE
	    return IPSEC_LEVEL_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_REQUIRE"))
#ifdef IPSEC_LEVEL_REQUIRE
	    return IPSEC_LEVEL_REQUIRE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_UNIQUE"))
#ifdef IPSEC_LEVEL_UNIQUE
	    return IPSEC_LEVEL_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPSEC_LEVEL_USE"))
#ifdef IPSEC_LEVEL_USE
	    return IPSEC_LEVEL_USE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPV6_AUTH_TRANS_LEVEL"))
#ifdef IPV6_AUTH_TRANS_LEVEL
	    return IPV6_AUTH_TRANS_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPV6_AUTH_NETWORK_LEVEL"))
#ifdef IPV6_AUTH_NETWORK_LEVEL
	    return IPV6_AUTH_NETWORK_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPV6_ESP_TRANS_LEVEL"))
#ifdef IPV6_ESP_TRANS_LEVEL
	    return IPV6_ESP_TRANS_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IPV6_EPS_NETWORK_LEVEL"))
#ifdef IPV6_EPS_NETWORK_LEVEL
	    return IPV6_EPS_NETWORK_LEVEL;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NI_NOFQDN"))
#ifdef NI_NOFQDN
	    return NI_NOFQDN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NI_NUMERICHOST"))
#ifdef NI_NUMERICHOST
	    return NI_NUMERICHOST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NI_NAMEREQD"))
#ifdef NI_NAMEREQD
	    return NI_NAMEREQD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NI_NUMERICSERV"))
#ifdef NI_NUMERICSERV
	    return NI_NUMERICSERV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NI_DGRAM"))
#ifdef NI_DGRAM
	    return NI_DGRAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NI_WITHSCOPEID"))
#ifdef NI_WITHSCOPEID
	    return NI_WITHSCOPEID;
#else
	    goto not_there;
#endif
 	break;
    case 'P':
	if (strEQ(name, "PF_INET6"))
#ifdef PF_INET6
	    return PF_INET6;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Socket6	PACKAGE = Socket6

double
constant(name,arg)
	char *		name
	int		arg

void
gethostbyname2(host, af)
	char *	host;
	int	af;
	PPCODE:
{
#ifdef HAVE_GETHOSTBYNAME2
	struct hostent *phe;
	int count, i;

	if ((phe = gethostbyname2(host, af)) != NULL) {
		for (count = 0; phe->h_addr_list[count]; ++count);
		EXTEND(sp, 4 + count);
		PUSHs(sv_2mortal(newSVpv((char *) phe->h_name,
					 strlen(phe->h_name))));
		PUSHs(sv_2mortal(newSVpv((char *) phe->h_aliases,
					 sizeof(char *))));
		PUSHs(sv_2mortal(newSViv((IV) phe->h_addrtype)));
		PUSHs(sv_2mortal(newSViv((IV) phe->h_length)));
		for (i = 0; i < count; ++i) {
			PUSHs(sv_2mortal(newSVpv((char *)phe->h_addr_list[i],
						 phe->h_length)));
		}
	}
#else
	ST(0) = (SV *) not_here("gethostbyname2");
#endif
}

void
inet_pton(af, host)
	int	af
	char *	host
	CODE:
{
#ifdef HAVE_INET_PTON
	union {
#ifdef INET6_ADDRSTRLEN
		struct in6_addr addr6;
#endif
		struct in_addr addr4;
	} ip_address;
	int len;
	int ok;

	switch (af) {
#ifdef INET6_ADDRSTRLEN
	case AF_INET6:
		len = sizeof(struct in6_addr);
		break;
#endif
	case AF_INET:
		len = sizeof(struct in_addr);
		break;
	default:
		croak("Bad address family for %s, got %d",
			"Socket6::inet_pton", af);
		break;
	}
	ok = inet_pton(af, host, &ip_address);

	ST(0) = sv_newmortal();
	if (ok == 1) {
		sv_setpvn( ST(0), (char *)&ip_address, len );
	}
#else
	ST(0) = (SV *) not_here("inet_pton");
#endif
}

void
inet_ntop(af, address_sv)
	int	af
	SV *	address_sv
	CODE:
{
#ifdef HAVE_INET_NTOP
	STRLEN addrlen, alen;
#ifdef INET6_ADDRSTRLEN
	struct in6_addr addr;
	char addr_str[INET6_ADDRSTRLEN];
#else
	struct in_addr addr;
	char addr_str[16];
#endif
	char * address = SvPV(address_sv,addrlen);

	switch (af) {
	case AF_INET:
		alen = sizeof(struct in_addr);
		break;
#ifdef INET6_ADDRSTRLEN
	case AF_INET6:
		alen = sizeof(struct in6_addr);
		break;
#endif
	default:
		croak("Unsupported address family for %s, af is %d",
		      "Socket6::inet_ntop", af);
	}

	/* with sanity check, just in case */
	if (alen > sizeof(addr) || alen != addrlen) {
		croak("Bad arg length for %s, length is %d, should be %d",
		      "Socket6::inet_ntop",
		      addrlen, alen);
	}

	Copy( address, &addr, alen, char );
	addr_str[0] = 0;
	inet_ntop(af, &addr, addr_str, sizeof addr_str);

	ST(0) = sv_2mortal(newSVpv(addr_str, strlen(addr_str)));
#else
	ST(0) = (SV *) not_here("inet_ntop");
#endif
}

void
pack_sockaddr_in6(port,ip6_address)
	unsigned short	port
	char *	ip6_address
	CODE:
{
#ifdef INET6_ADDRSTRLEN
	struct sockaddr_in6 sin;

	Zero( &sin, sizeof sin, char );
#ifdef SIN6_LEN
	sin.sin6_len = sizeof sin;
#endif
	sin.sin6_family = AF_INET6;
	sin.sin6_port = htons(port);
	Copy( ip6_address, &sin.sin6_addr, sizeof sin.sin6_addr, char );

	ST(0) = sv_2mortal(newSVpv((char *)&sin, sizeof sin));
#else
	ST(0) = (SV *) not_here("pack_sockaddr_in6");
#endif
}

void
pack_sockaddr_in6_all(port,flowinfo,ip6_address,scope_id)
	unsigned short	port
	unsigned long	flowinfo
	char *	ip6_address
	unsigned long	scope_id
	CODE:
{
#ifdef INET6_ADDRSTRLEN
	struct sockaddr_in6 sin;

	Zero( &sin, sizeof sin, char );
#ifdef SIN6_LEN
	sin.sin6_len = sizeof sin;
#endif
	sin.sin6_family = AF_INET6;
	sin.sin6_port = htons(port);
	sin.sin6_flowinfo = htonl(flowinfo);
	Copy( ip6_address, &sin.sin6_addr, sizeof sin.sin6_addr, char );
#ifdef HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
	sin.sin6_scope_id = scope_id;
#endif

	ST(0) = sv_2mortal(newSVpv((char *)&sin, sizeof sin));
#else
	ST(0) = (SV *) not_here("pack_sockaddr_in6_all");
#endif
}

void
unpack_sockaddr_in6(sin_sv)
	SV *	sin_sv
	PPCODE:
{
#ifdef INET6_ADDRSTRLEN
	STRLEN sockaddrlen;
	struct sockaddr_in6 addr;
	unsigned short	port;
	struct in6_addr	ip6_address;
	char *	sin = SvPV(sin_sv,sockaddrlen);
	if (sockaddrlen != sizeof(addr)) {
		croak("Bad arg length for %s, length is %d, should be %d",
		      "Socket6::unpack_sockaddr_in6",
		      sockaddrlen, sizeof(addr));
	}
	Copy( sin, &addr,sizeof addr, char );
	if ( addr.sin6_family != AF_INET6 ) {
		croak("Bad address family for %s, got %d, should be %d",
		      "Socket6::unpack_sockaddr_in6",
		      addr.sin6_family,
		      AF_INET6);
	}
	port = ntohs(addr.sin6_port);
	ip6_address = addr.sin6_addr;

	EXTEND(sp, 2);
	PUSHs(sv_2mortal(newSViv((IV) port)));
	PUSHs(sv_2mortal(newSVpv((char *)&ip6_address,sizeof ip6_address)));
#else
	ST(0) = (SV *) not_here("unpack_sockaddr_in6");
#endif
}

void
unpack_sockaddr_in6_all(sin_sv)
	SV *	sin_sv
	PPCODE:
{
#ifdef INET6_ADDRSTRLEN
	STRLEN sockaddrlen;
	struct sockaddr_in6 addr;
	unsigned short	port;
	unsigned long	flowinfo;
	struct in6_addr	ip6_address;
	unsigned long	scope_id;
	char *	sin = SvPV(sin_sv,sockaddrlen);
	if (sockaddrlen != sizeof(addr)) {
		croak("Bad arg length for %s, length is %d, should be %d",
		      "Socket6::unpack_sockaddr_in6",
		      sockaddrlen, sizeof(addr));
	}
	Copy( sin, &addr,sizeof addr, char );
	if ( addr.sin6_family != AF_INET6 ) {
		croak("Bad address family for %s, got %d, should be %d",
		      "Socket6::unpack_sockaddr_in6",
		      addr.sin6_family,
		      AF_INET6);
	}
	port = ntohs(addr.sin6_port);
	flowinfo = ntohl(addr.sin6_flowinfo);
	ip6_address = addr.sin6_addr;
#ifdef HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
	scope_id = addr.sin6_scope_id;
#else
	scope_id = 0;
#endif

	EXTEND(sp, 5);
	PUSHs(sv_2mortal(newSViv((IV) port)));
	PUSHs(sv_2mortal(newSViv((IV) flowinfo)));
	PUSHs(sv_2mortal(newSVpv((char *)&ip6_address,sizeof ip6_address)));
	PUSHs(sv_2mortal(newSViv((IV) scope_id)));
#else
	ST(0) = (SV *) not_here("unpack_sockaddr_in6_all");
#endif
}

void
in6addr_any()
	CODE:
{
#ifdef INET6_ADDRSTRLEN
	ST(0) = sv_2mortal(newSVpv((char *)&in6addr_any, sizeof in6addr_any));
#else
	ST(0) = (SV *) not_here("in6addr_any");
#endif
}

void
in6addr_loopback()
	CODE:
{
#ifdef INET6_ADDRSTRLEN
	ST(0) = sv_2mortal(newSVpv((char *)&in6addr_loopback,
				   sizeof in6addr_loopback));
#else
	ST(0) = (SV *) not_here("in6addr_loopback");
#endif
}

void
getaddrinfo(host,port,family=0,socktype=0,protocol=0,flags=0)
	char *	host
	char *	port
	int	family
	int	socktype
	int	protocol
	int	flags
	PPCODE:
{
#ifdef HAVE_GETADDRINFO
	struct addrinfo hints, * res;
	int	err;
	int	count;
	const char	*error;
	WSA_DECLARE;

	Zero( &hints, sizeof hints, char );
	hints.ai_flags = flags;
	hints.ai_family = family;
	hints.ai_socktype = socktype;
	hints.ai_protocol = protocol;
	WSA_STARTUP();
	err = getaddrinfo(*host ? host : 0, *port ? port : 0, &hints, &res);
	WSA_CLEANUP();

	if (err == 0) {
		struct addrinfo * p;
		count = 0;
		for (p = res; p; p = p->ai_next)
			++count;
		EXTEND(sp, 5 * count);
		for (p = res; p; p = p->ai_next) {
			PUSHs(sv_2mortal(newSViv((IV) p->ai_family)));
			PUSHs(sv_2mortal(newSViv((IV) p->ai_socktype)));
			PUSHs(sv_2mortal(newSViv((IV) p->ai_protocol)));
			PUSHs(sv_2mortal(newSVpv((char *)p->ai_addr,
			      p->ai_addrlen)));
			if (p->ai_canonname)
				PUSHs(sv_2mortal(newSVpv((char *)p->ai_canonname,
				      strlen(p->ai_canonname))));
			else
				PUSHs(&PL_sv_undef);
		}
		freeaddrinfo(res);
	} else  {
		SV *error_sv = sv_newmortal();
		SvUPGRADE(error_sv, SVt_PVNV);
		error = gai_strerror(err);
		sv_setpv(error_sv, error);
		SvIV_set(error_sv, err); SvIOK_on(error_sv);
		PUSHs(error_sv);
	}
#else
	ST(0) = (SV *) not_here("getaddrinfo");
#endif
}

void
getnameinfo(sin_sv, flags = 0)
	SV *	sin_sv
	int flags;
	PPCODE:
{
#ifdef HAVE_GETNAMEINFO
	STRLEN sockaddrlen;
	struct sockaddr * sin = (struct sockaddr *)SvPV(sin_sv,sockaddrlen);
	char host[NI_MAXHOST];
	char port[NI_MAXSERV];
	int	err;
	const char	*error;
	WSA_DECLARE;

	WSA_STARTUP();
	if (items < 2) {
		err = getnameinfo(sin, sockaddrlen, host, sizeof host,
				  port, sizeof port, 0);
		if (err)
			err = getnameinfo(sin, sockaddrlen, host, sizeof host,
					  port, sizeof port, NI_NUMERICSERV);
		if (err)
			err = getnameinfo(sin, sockaddrlen, host, sizeof host,
					  port, sizeof port, NI_NUMERICHOST);
		if (err)
			err = getnameinfo(sin, sockaddrlen, host, sizeof host,
					  port, sizeof port,
					  NI_NUMERICHOST|NI_NUMERICSERV);
	} else {
		err = getnameinfo(sin, sockaddrlen, host, sizeof host,
				  port, sizeof port, flags);
	}
	WSA_CLEANUP();

	if (err == 0) {
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVpv(host, strlen(host))));
		PUSHs(sv_2mortal(newSVpv(port, strlen(port))));
	} else  {
		SV *error_sv = sv_newmortal();
		SvUPGRADE(error_sv, SVt_PVNV);
		error = gai_strerror(err);
		sv_setpv(error_sv, error);
		SvIV_set(error_sv, err); SvIOK_on(error_sv);
		PUSHs(error_sv);
	}
#else
	ST(0) = (SV *) not_here("getnameinfo");
#endif
}

char *
gai_strerror(errcode = 0)
	int	errcode;
	CODE:
	RETVAL = (char *)gai_strerror(errcode);
	OUTPUT:
	RETVAL

void
getipnodebyname(hostname, family=0, flags=0)
	char *	hostname
	int	family
	int	flags
	PREINIT:
#ifdef HAVE_GETIPNODEBYNAME
	struct hostent	*he;
	int		err;
	char		**p;
	SV		*temp, *address_ref, *alias_ref;
	AV		*address_list, *alias_list;
#endif
	PPCODE:
{
#ifdef HAVE_GETIPNODEBYNAME
	he = getipnodebyname(hostname, family, flags, &err);

	if (err == 0) {
		XPUSHs(sv_2mortal(newSVpv(he->h_name, strlen(he->h_name))));
		XPUSHs(sv_2mortal(newSViv(he->h_addrtype)));
		XPUSHs(sv_2mortal(newSViv(he->h_length)));

		address_list = newAV();
		for(p = he->h_addr_list; *p != NULL; p++) {
			temp = newSVpv(*p, he->h_length);
			av_push(address_list, temp);
		}
		address_ref = newRV_noinc((SV*) address_list);
		XPUSHs(address_ref);

		alias_list = newAV();
		for(p = he->h_aliases; *p != NULL; p++) {
			temp = newSVpv(*p, strlen(*p));
			av_push(alias_list, temp);
		}
		alias_ref = newRV_noinc((SV*) alias_list);
		XPUSHs(alias_ref);
		freehostent(he);
	} else {
		XPUSHs(sv_2mortal(newSViv(err)));
	}
#else
	ST(0) = (SV *) not_here("getipnodebyname");
#endif
}

void
getipnodebyaddr(family, address_sv)
	int	family
	SV *	address_sv
	PREINIT:
#ifdef HAVE_GETIPNODEBYADDR
	STRLEN		addrlen;
	struct hostent	*he;
	int		err, alen;
	char		**p;
	SV		*temp, *address_ref, *alias_ref;
	AV		*address_list, *alias_list;
	struct in6_addr	addr;
	char		*addr_buffer;
#endif
	PPCODE:
{
#ifdef HAVE_GETIPNODEBYADDR
	addr_buffer = SvPV(address_sv, addrlen);

	switch(family) {

	case AF_INET:
		alen = sizeof(struct in_addr);
		break;
	case AF_INET6:
		alen = sizeof(struct in6_addr);
		break;
	default:
		croak("Unsupported address family for %s, af is %d",
		    "Socket6::getipnodebyaddr", family);
	}

	if (alen > sizeof(addr) || alen != addrlen) {
		croak("Arg length mismatch in %s, length is %d, should be %d\n",
		    "Socket6::getipnodebyaddr", addrlen, alen);
	}

	Copy(addr_buffer, &addr, sizeof(addr), char);

	he = getipnodebyaddr(addr_buffer, alen, family, &err);

	if (err == 0) {
		XPUSHs(sv_2mortal(newSVpv(he->h_name, strlen(he->h_name))));
		XPUSHs(sv_2mortal(newSViv(he->h_addrtype)));
		XPUSHs(sv_2mortal(newSViv(he->h_length)));

		address_list = newAV();
		for(p = he->h_addr_list; *p != NULL; p++) {
			temp = newSVpv(*p, he->h_length);
			av_push(address_list, temp);
		}
		address_ref = newRV_noinc((SV*) address_list);
		XPUSHs(address_ref);

		alias_list = newAV();
		for(p = he->h_aliases; *p != NULL; p++) {
			temp = newSVpv(*p, strlen(*p));
			av_push(alias_list, temp);
		}
		alias_ref = newRV_noinc((SV*) alias_list);
		XPUSHs(alias_ref);
		freehostent(he);
	} else {
		XPUSHs(sv_2mortal(newSViv(err)));
	}
#else
	ST(0) = (SV *) not_here("getipnodebyaddr");
#endif
}
