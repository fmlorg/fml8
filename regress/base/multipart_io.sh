#!/bin/sh
#
# $FML: multipart_io.sh,v 1.9 2001/04/13 04:32:30 fukachan Exp $
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


echo "* text operations test"
xdir=$dir/../testmails

for x in $xdir/text*
do
   env test_mode=1 ../message/basic_io.pl $x
done


echo "* multipart operations test"
xdir=$dir/../testmails

for x in $xdir/multipart*
do
   DIFF $x
done


echo "   ++ errormails/ has broken multipart messages ;0"
xdir=$dir/../errormails

# ../errormails has broken multipart messages ;0
grep -i -l multipart $xdir/[a-z]*[a-z0-9] |\
grep -v odn.ne.jp |\
while read file
do
	DIFF $file
done
echo "   ++ errormails/ test ends"; echo ""

exit 0;
