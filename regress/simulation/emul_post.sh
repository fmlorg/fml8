#!/bin/sh
#
# $FML: emul_post.sh,v 1.1 2001/10/12 09:01:24 fukachan Exp $
#

DO () {
   (
	pwd=`pwd`
	cd ../.. || exit 1
	pwd

	test -f $msg || return;

	maincf=/tmp/main.cf.$$
	trap "rm -f $maincf" 0 1 3 15
	sed -e "s@\$pwd@$PWD@g" regress/simulation/main.cf > $maincf

	regress/message/scramble.pl $msg |\
	${PERL:-perl} -w fml/libexec/loader -c $maincf \
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

