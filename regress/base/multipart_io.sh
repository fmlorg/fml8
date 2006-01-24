#!/bin/sh
#
# $FML: multipart_io.sh,v 1.10 2001/06/17 09:00:29 fukachan Exp $
#

PERL="perl -I ../lib -I ../../fml/lib -I ../../cpan/lib -I ../../img/lib"

dir=`dirname $0`

tmp=/tmp/buf$$

trap "rm -f $tmp" 0 1 3 15


DIFF () {
	local msg=$1
	local file=`basename $msg`
 
	sed -n '1,/^$/p' $msg > $tmp
	$PERL $dir/multipart_io.pl $msg  >> $tmp

	ok=0
	diff -ub $msg $tmp > /dev/null && ok=1 || ok=0 
	if [ $ok = 1 ];then
		printf "%-40s ... %s\n" `basename $file` "ok"
	else
		printf "%-40s ... %s\n" `basename $file` "fail"
	fi
}


echo "=> basic message"
xdir=$dir/../testmails

for x in $xdir/text*
do
   env test_mode=1 $PERL ../message/basic_io.pl $x
done


echo "=> multipart"
xdir=$dir/../testmails

for x in $xdir/multipart*
do
   DIFF $x
done

echo "=> errormails"
# echo "   ++ errormails/ has broken multipart messages ;0"
xdir=$dir/../errormails

# ../errormails has broken multipart messages ;0
grep -i -l multipart $xdir/[a-z]*[a-z0-9] |\
grep -v odn.ne.jp |\
while read file
do
	DIFF $file
done
# echo "   ++ errormails/ test ends"; echo ""

exit 0;
