#!/bin/sh
#
# $FML: emul_error.sh,v 1.1 2002/11/25 14:30:57 fukachan Exp $
#

DO () {
   (
	pwd=`pwd`
	cd ../.. || exit 1
	pwd

	test -f $msg || return;

	regress/message/scramble.pl $msg |\
	${PERL:-perl} -w /usr/local/libexec/fml/error elena@home.fml.org

	echo "-- exit code: $?"
   )
}

if [ "X$*" != X ];then
	list=$*
else
	pwd=`pwd`
	list=$pwd/../errormails/postfix19991231
fi

for msg in $list
do
   DO $msg
done

printf "\n\n" ; fml elena error

exit 0
