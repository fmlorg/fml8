#!/bin/sh
#
# $FML: test.sh,v 1.8 2001/04/14 14:35:08 fukachan Exp $
#

DO () {
   (
	pwd=`pwd`
	cd ../.. || exit 1
	pwd

	test -f $msg || return;

	regress/message/scramble.pl $msg |\
	${PERL:-perl} -w fml/libexec/loader \
		--params pwd=$PWD \
		-c $pwd/main.cf \
		/var/spool/ml/elena
	echo "-- exit code: $?"
   )
}

if [ "X$*" != X ];then
	list=$*
else
	pwd=`pwd`
	list=$pwd/../testmails/text=plain
fi

(cd ../../fml/etc/;sh .gen.sh)

for msg in $list
do
   DO $msg
done

exit 0

