#!/bin/sh
#
# $FML$
#

ml_home_dir=/var/spool/ml/elena
tmp_dir=/tmp/.fml

test -d $tmp_dir || rm -fr $tmp_dir
test -d $tmp_dir || mkdir $tmp_dir

for x in $ml_home_dir/member*[a-z] \
	 $ml_home_dir/recipient*[a-z] \
	 $ml_home_dir/etc/[a-z]*[a-z]
do
   y=`basename $x`
   cp $x $tmp_dir/$y
done

echo fml $*
eval fml $*

for x in $ml_home_dir/member*[a-z] \
	 $ml_home_dir/recipient*[a-z] \
	 $ml_home_dir/etc/[a-z]*[a-z]
do
   y=`basename $x`

   if [ -f $tmp_dir/$y ];then
	diff -ub $tmp_dir/$y $x |\
	sed -e 's/^---.*//' 
   else
	echo "";
	echo "+++ $x creaetd"
	cat $x
   fi
done

exit 0
