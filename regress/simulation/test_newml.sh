SHOW () {
	head -30 /tmp/nuinui/*rudo/include* \
		/tmp/nuinui/etc/mail/aliases \
		/tmp/nuinui/etc/postfix/virtual \
		/tmp/nuinui/etc/qmail/virtualdomains 
}


(
	rm -fr /tmp/nuinui 
	sh reset_lib.sh 

	printf "\n*** newml *** \n\n"

	printf "\n\n\n" > /dev/stderr 
	makefml newml rudo@nuinui.net 
	SHOW

	printf "\n*** rmml *** \n\n"

	printf "\n\n\n" > /dev/stderr 
	makefml rmml rudo@nuinui.net 
	SHOW

) 2>&1 | tee /tmp/rr
