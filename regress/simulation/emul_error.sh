#!/bin/sh
#
# $FML: emul_error.sh,v 1.3 2004/04/07 12:17:32 fukachan Exp $
#

DO () {
   (
	pwd=`pwd`
	cd ../.. || exit 1
	pwd

	test -f $msg || return;

	regress/message/scramble.pl $msg |\
	${PERL:-perl} -w /usr/local/libexec/fml/error \
	-o use_debug=yes \
	-o error_mail_analyzer_function=simple_count \
	-o error_mail_analyzer_simple_count_limit=2 \
 	elena@home.fml.org

	echo "-- exit code: $?"
   )
}

if [ "X$*" != X ];then
	list=$*
else
	pwd=`pwd`
	list=$pwd/../errormails/postfix19991231
fi

sh reset_lib.sh

for msg in $list
do
   DO $msg
done

printf "\n\n" ; fml elena error

exit 0
