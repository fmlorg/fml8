#!/bin/sh
#
# $FML: test-ctl.sh,v 1.1 2001/10/08 15:42:01 fukachan Exp $
#

buf=$PWD/__command$$__
trap "rm -f $buf" 0 1 3 15


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

