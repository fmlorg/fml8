#!/bin/sh
#
# $FML$
#

list=/tmp/list.todo.$$

DIFF () {

   local dir1=$1
   local dir2=$2

   for dir in $dir1 $dir2
   do
	find $dir -type f -print |\
	sed "s|$dir/||" |\
	egrep -v CVS/ |\
	sort > /tmp/list.$dir
   done

   diff -ub /tmp/list.$dir1 /tmp/list.$dir2 |\
   egrep '^\-[a-z]' |\
   sed 's/^-//' |\
   awk '{print $1}' > $list

   for dir in $dir1 $dir2
   do
	for file in `cat $list`
	do
	    _dir=`dirname $dir/$file`
	    test -d $_dir || mkdir -p $_dir
	    if [ ! -f $dir/$file ];then
		echo touch $dir/$file |tee -a TODO
		eval touch $dir/$file
		sed 's/^/# /' euc-jp/$file >> $dir/$file
	    fi
	done
   done
}

find . -size 0 -print|perl -nple unlink
DIFF euc-jp us-ascii

exit 0;

