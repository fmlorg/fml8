#!/bin/sh
#
# $FML: .gen.sh,v 1.4 2001/11/27 09:30:40 fukachan Exp $
#

tmp=default_config.cf.xx.$$

trap "rm -f $tmp" 0 1 3 15

for lang in ja
do
	test -f $tmp || rm -f $tmp

	cat src/list.cf | while read file 
	do
		cat src/config.cf.$lang/$file >> $tmp
		echo "" >> $tmp
	done

	mv $tmp default_config.cf.$lang.in

	if [ -f default_config.cf.$lang.in ];then 
		echo default_config.cf.$lang.in created
	fi
done

exit 0
