#!/bin/sh

dir=`dirname $0`

tmp=/tmp/buf$$

trap "rm -f $tmp" 0 1 3 15


DIFF () {
	local msg=$1
 
	sed -n '1,/^$/p' $msg > $tmp
	perl $dir/multipart_io.pl $msg  >> $tmp
	diff -ub $msg $tmp && echo ok || echo fail
}

xdir=$dir/../testmails
DIFF $xdir/multipart=mixed
DIFF $xdir/multipart=mixed-preamble
DIFF $xdir/multipart=mixed-trailor

exit 0;
