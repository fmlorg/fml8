#!/bin/sh
#
# $Id$
#

jatmp=default_config.cf.ja.$$
entmp=default_config.cf.en.$$

trap "rm -f $jatmp $entmp" 0 1 3 15

test -f $jatmp || rm -f $jatmp

cat defaults/Configurations | while read file 
do
	cat defaults/$file.ja >> $jatmp
done

mv $jatmp default_config.cf.ja

exit 0
