#!/bin/sh
#
# $Id$
#

dir=`dirname $0`

tmp=/tmp/buf$$

trap "rm -f $tmp" 0 1 3 15


DIFF () {
	local msg=$1
	local file=`basename $msg`
 
	sed -n '1,/^$/p' $msg > $tmp
	perl $dir/multipart_io.pl $msg  >> $tmp
	diff -ub $msg $tmp && echo $file ok || echo $file fail
}

xdir=$dir/../testmails
DIFF $xdir/multipart=mixed
DIFF $xdir/multipart=mixed-preamble
DIFF $xdir/multipart=mixed-trailor

xdir=$dir/../errormails

echo "   ++ errormails/ has broken multipart messages ;0"
# ../errormails has broken multipart messages ;0
grep -i -l multipart $xdir/[a-z]*[a-z0-9] |\
grep -v odn.ne.jp |\
while read file
do
	DIFF $file
done
echo "   ++ errormails/ test ends"; echo ""

exit 0;
