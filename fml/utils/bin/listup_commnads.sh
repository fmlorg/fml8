#!/bin/sh
#
# $FML$
#

cd `dirname $0`/../../.. || exit 1

test -d fml/doc/share/config  || mkdir -p fml/doc/share/config 

echo generating user command list 1>&2
(
	fmlconf __default__ commands_for_user | sed 's/.*= *//'
	fmlconf __default__ commands_for_stranger  | sed 's/.*= *//'
) |\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_user_command.txt

echo generating admin command list 1>&2
(
	fmlconf __default__ commands_for_privileged_user | sed 's/.*= *//'
) |\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_admin_command.txt

echo generating admin.cgi command list 1>&2
(
	fmlconf __default__ commands_for_admin_cgi | sed 's/.*= *//'
)|\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_admin_cgi_command.txt

echo generating makefml command list 1>&2
apply basename fml/lib/FML/Command/Admin/*.pm |\
sed 's/.pm$//' |\
tr ' ' '\012' | sort | uniq > fml/doc/share/config/list_makefml_command.txt

exit 0


