#!/bin/sh
#
# $FML$
#

SHOW () {
	head -30 /tmp/nuinui/*rudo/include* \
		/tmp/nuinui/etc/mail/aliases \
		/tmp/nuinui/etc/postfix/virtual \
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
