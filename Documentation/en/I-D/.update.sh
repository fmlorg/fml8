#!/bin/sh
#
# $FML: .update.sh,v 1.1 2001/11/17 11:36:45 fukachan Exp $
#

chmod 644 draft-*

apply echo draft-*txt | sed 's@\-[0-9][0-9].txt@@' | while read file
do
   for x in $HOME/.I-D/${file}*.txt $HOME/.I-D/${file}*.txt.gz
   do
	if [ -f $x ]; then
		echo cp $x .
		eval cp $x .
	fi
   done 
done

exit 0
