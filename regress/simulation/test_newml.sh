#!/bin/sh
#
# $FML: test_newml.sh,v 1.5 2003/01/04 14:08:54 fukachan Exp $
#

SHOW () {
	echo "";
	echo "******************* show config *******************"; 
	echo "";

	head -30 /tmp/nuinui/*rudo/include* \
		/tmp/nuinui/etc/mail/aliases \
		/tmp/nuinui/etc/postfix/virtual \
		/tmp/nuinui/etc/sendmail/virtusertable \
		/tmp/nuinui/etc/procmail/procmailrc \
		/tmp/nuinui/etc/qmail/virtualdomains 

	echo ""
	head $HOME/.qmail-*nuinui*

	echo "";
	echo "******************* show config end *******************"; 
	echo "";
}


(
	rm -fr /tmp/nuinui 
	sh reset_lib.sh 

	printf "\n*** newml *** \n\n"

	printf "\n\n\n" > /dev/stderr 
	makefml newml rudo@nuinui.net 
	SHOW

	test -d /tmp/nuinui || echo error: /tmp/nuinui not exist
	test -d /tmp/nuinui || exit 1

	ls -lRa /tmp/nuinui

	printf "\n*** rmml *** \n\n"

	printf "\n\n\n" > /dev/stderr 
	makefml rmml rudo@nuinui.net 
	SHOW

) 2>&1 | tee /tmp/rr

echo "";
echo "---";
echo "";
echo See /tmp/rr
echo "";

exit 0
