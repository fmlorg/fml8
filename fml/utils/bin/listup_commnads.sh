#!/bin/sh
#
# $FML: listup_commnads.sh,v 1.1 2002/09/29 06:06:21 fukachan Exp $
#

cd `dirname $0`/../../.. || exit 1

test -d fml/doc/share/config  || mkdir -p fml/doc/share/config 

echo generating user command list 1>&2
(
	fmlconf __default__ user_command_mail_allowed_commands |\
	sed 's/.*= *//'

	fmlconf __default__ anonymous_command_mail_allowed_commands  |\
	sed 's/.*= *//'
) |\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_user_command.txt

echo generating admin command list 1>&2
(
	fmlconf __default__ admin_command_mail_allowed_commands |\
	sed 's/.*= *//'
) |\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_admin_command.txt

echo generating admin.cgi command list 1>&2
(
	fmlconf __default__ admin_cgi_allowed_commands |\
	sed 's/.*= *//'
)|\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_admin_cgi_command.txt

echo generating makefml command list 1>&2
apply basename fml/lib/FML/Command/Admin/*.pm |\
sed 's/.pm$//' |\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_makefml_command.txt

exit 0


