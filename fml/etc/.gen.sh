#!/bin/sh
#
# $FML: .gen.sh,v 1.3 2001/06/17 08:57:08 fukachan Exp $
#

jatmp=default_config.cf.ja.$$
entmp=default_config.cf.en.$$

trap "rm -f $jatmp $entmp" 0 1 3 15

test -f $jatmp || rm -f $jatmp

cat defaults/Configurations | while read file 
do
	cat defaults/$file.ja >> $jatmp
	echo "" >> $jatmp
done

mv $jatmp default_config.cf.ja.in

exit 0
