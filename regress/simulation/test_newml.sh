#!/bin/sh
#
# $FML: test_newml.sh,v 1.4 2002/12/31 03:57:56 fukachan Exp $
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

echo "";
echo "---";
echo "";
echo See /tmp/rr
echo "";

exit 0
