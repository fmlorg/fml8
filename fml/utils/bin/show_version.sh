#!/bin/sh
#
# $FML$
#

if [ -f CHANGES.txt ];then
	version=`egrep '^  *FML_CURRENT_VERSION' CHANGES.txt|sed 's/.*=//' `
	echo fml-$version
else
	exit 1
fi

exit 0;
