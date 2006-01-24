#!/bin/sh
#
# $FML: multipart_maker.sh,v 1.6 2001/06/17 09:00:29 fukachan Exp $
#

PERL="perl -I ../lib -I ../../fml/lib -I ../../cpan/lib -I ../../img/lib"

dir=`dirname $0`

tmp=/tmp/buf$$
buf=/tmp/buf2-$$
log=/tmp/log$$

trap "rm -f $tmp $buf $log" 0 1 3 15


DIFF () {
	cat $1 $2 $3 > $buf
	$PERL $dir/multipart_maker.pl $1 $2 $3 > $tmp

	ok=0
	diff -ub $buf $tmp > $log && ok=1 || ok=0
	if [ $ok -eq 1 ];then
		printf "%-40s ... ok\n" "aggregate $1 $2 $3"
	else
		printf "%-40s ... fail\n" "aggregate $1 $2 $3"
	fi

   # if debug
	# echo ""
	# sed -n -e 1,2d -e '/^\+/p' -e '/^\-/p' $log|sed -e 's/^/   /' 
	# echo ""
   # fi
}

DIFF /etc/fml/main.cf
DIFF /etc/fml/main.cf /etc/group

exit 0;
