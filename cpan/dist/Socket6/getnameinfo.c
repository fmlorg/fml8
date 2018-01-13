/*
 * Mar  8, 2000 by Hajimu UMEMOTO <ume@mahoroba.org>
 * $Id: getnameinfo.c 99 2004-01-04 10:13:44Z ume $
 *
 * This module is besed on ssh-1.2.27-IPv6-1.5 written by
 * KIKUCHI Takahiro <kick@kyoto.wide.ad.jp>
 */
/*
 * fake library for ssh
 *
 * This file includes getnameinfo().
 * These funtions are defined in rfc2133.
 *
 * But these functions are not implemented correctly. The minimum subset
 * is implemented for ssh use only. For exapmle, this routine assumes
 * that ai_family is AF_INET. Don't use it for another purpose.
 * 
 * In the case not using 'configure --enable-ipv6', this getnameinfo.c
 * will be used if you have broken getnameinfo or no getnameinfo.
 */

#include <string.h>
#include "gai.h"

#ifndef HAVE_SOCKLEN_T
typedef unsigned int socklen_t;
#endif /* HAVE_SOCKLEN_T */

int
getnameinfo(const struct sockaddr *sa, socklen_t salen,
	    char *host, size_t hostlen, char *serv, size_t servlen, int flags)
{
    struct sockaddr_in *sin = (struct sockaddr_in *)sa;
    struct hostent *hp;
    char tmpserv[16];
  
    if (serv) {
	snprintf(tmpserv, sizeof(tmpserv), "%d", ntohs(sin->sin_port));
	if (strlen(tmpserv) > servlen)
	    return EAI_MEMORY;
	else
	    strcpy(serv, tmpserv);
    }
    if (host) {
	if (flags & NI_NUMERICHOST) {
	    if (flags & NI_NAMEREQD)
		return EAI_NONAME;
	    if (strlen(inet_ntoa(sin->sin_addr)) >= hostlen)
		return EAI_MEMORY;
	    else {
		strcpy(host, inet_ntoa(sin->sin_addr));
		return 0;
	    }
	} else {
	    hp = gethostbyaddr((char *)&sin->sin_addr,
			       sizeof(struct in_addr), AF_INET);
	    if (hp)
		if (strlen(hp->h_name) >= hostlen)
		    return EAI_MEMORY;
		else {
		    strcpy(host, hp->h_name);
		    return 0;
		}
	    else if (flags & NI_NAMEREQD)
		return EAI_NONAME;
	    else if (strlen(inet_ntoa(sin->sin_addr)) >= hostlen)
		return EAI_MEMORY;
	    else {
		strcpy(host, inet_ntoa(sin->sin_addr));
		return 0;
	    }
	}
    }
    return 0;
}
