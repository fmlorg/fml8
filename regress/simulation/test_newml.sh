#!/bin/sh
#
# $FML: test_newml.sh,v 1.6 2003/04/18 15:58:57 fukachan Exp $
#

SHOW () {
	echo "";
	echo "******************* show config *******************"; 
	echo "";

	head -30 \
		/etc/fml/ml_home_prefix \
		/tmp/nuinui/*rudo/include* \
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
	test -d /tmp/nuinui || mv /tmp/nuinui /tmp/nuinui.$$

	rm -fr /tmp/nuinui
	sh reset_lib.sh 

	printf "\n*** newdomain *** \n\n"
	makefml newdomain - nuinui.net /tmp/nuinui

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

	printf "\n*** rmdomain *** \n\n"
	makefml rmdomain - nuinui.net

	printf "\n\n\n" > /dev/stderr 
	SHOW

) 2>&1 | tee /tmp/rr

echo "";
echo "---";
echo "";
echo See /tmp/rr
echo "";

exit 0
