/*
 * Mar  8, 2000 by Hajimu UMEMOTO <ume@mahoroba.org>
 * $Id: gai.h,v 1.4 2000/05/27 19:16:43 ume Exp $
 *
 * This module is besed on ssh-1.2.27-IPv6-1.5 written by
 * KIKUCHI Takahiro <kick@kyoto.wide.ad.jp>
 */
/*
 * fake library for ssh
 *
 * This file is included in getaddrinfo.c and getnameinfo.c.
 * See getaddrinfo.c and getnameinfo.c.
 */

/* for old netdb.h */
#ifndef EAI_NODATA
#define EAI_NODATA	1
#define EAI_MEMORY	2
#define EAI_FAMILY	5	/* ai_family not supported */
#define EAI_SERVICE	9	/* servname not supported for ai_socktype */
#endif

/* dummy value for old netdb.h */
#ifndef AI_PASSIVE
#define AI_PASSIVE	1
#define AI_CANONNAME	2
#define NI_NUMERICHOST	2
#define NI_NAMEREQD	4
#define NI_NUMERICSERV	8
struct addrinfo {
	int	ai_flags;	/* AI_PASSIVE, AI_CANONNAME */
	int	ai_family;	/* PF_xxx */
	int	ai_socktype;	/* SOCK_xxx */
	int	ai_protocol;	/* 0 or IPPROTO_xxx for IPv4 and IPv6 */
	size_t	ai_addrlen;	/* length of ai_addr */
	char	*ai_canonname;	/* canonical name for hostname */
	struct sockaddr *ai_addr;	/* binary address */
	struct addrinfo *ai_next;	/* next structure in linked list */
};
#endif
