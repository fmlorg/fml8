#!/bin/sh
#
# $FML$
#


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
