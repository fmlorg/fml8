#!/bin/sh
#
# $FML: emul_command.sh,v 1.1 2001/10/12 09:01:24 fukachan Exp $
#

buf=$PWD/__command$$__
trap "rm -f $buf" 0 1 3 15


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
		--ctladdr \
		/var/spool/ml/elena
	echo "-- exit code: $?"
   )
}

(cd ../../fml/etc/;sh .gen.sh)


cat ./../testmails/text=empty > $buf
cat >> $buf

list=$buf

for msg in $list
do
   DO $msg
done

exit 0

