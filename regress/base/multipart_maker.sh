#!/bin/sh
#
# $Id$
#

dir=`dirname $0`

tmp=/tmp/buf$$
buf=/tmp/buf2-$$
log=/tmp/log$$

trap "rm -f $tmp $buf $log" 0 1 3 15


DIFF () {
	cat $1 $2 $3 > $buf
	perl $dir/multipart_maker.pl $1 $2 $3 > $tmp
	diff -ub $buf $tmp > $log && echo ok || echo " aggregate $1 $2 $3"
	echo ""
	sed -n -e 1,2d -e '/^\+/p' -e '/^\-/p' $log|sed -e 's/^/   /' 
	echo ""
}

DIFF /etc/fml/main.cf
DIFF /etc/fml/main.cf /etc/group

exit 0;
