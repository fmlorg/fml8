#!/bin/sh
#
# $FML: test_newml.sh,v 1.3 2002/12/26 14:55:50 fukachan Exp $
#

SHOW () {
	head -30 /tmp/nuinui/*rudo/include* \
		/tmp/nuinui/etc/mail/aliases \
		/tmp/nuinui/etc/postfix/virtual \
		/tmp/nuinui/etc/sendmail/virtusertable \
		/tmp/nuinui/etc/qmail/virtualdomains 
}


(
	rm -fr /tmp/nuinui 
	sh reset_lib.sh 

	echo mkdir /tmp/nuinui 
	mkdir /tmp/nuinui 

	printf "\n*** newml *** \n\n"

	printf "\n\n\n" > /dev/stderr 
	makefml newml rudo@nuinui.net 
	SHOW

	ls -lRa /tmp/nuinui

	printf "\n*** rmml *** \n\n"

	printf "\n\n\n" > /dev/stderr 
	makefml rmml rudo@nuinui.net 
	SHOW

) 2>&1 | tee /tmp/rr

echo See /tmp/rr

exit 0
