#!/bin/sh
#
# $Id$
#

dir=`dirname $0`

tmp=/tmp/buf$$
buf=/tmp/buf2-$$

trap "rm -f $tmp $buf" 0 1 3 15


DIFF () {
	local msg=$1
 
	perl $dir/multipart_maker.pl $msg > $buf
	sed '1,/^$/d' $buf > $tmp

	diff -ub $msg $tmp && echo ok || echo fail
}

DIFF /etc/fml/main.cf

exit 0;
