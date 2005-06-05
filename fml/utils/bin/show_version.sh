#!/bin/sh
#
# $FML: show_version.sh,v 1.1 2005/06/04 09:47:41 fukachan Exp $
#

if [ -f CHANGES.txt ];then
	version=`egrep '^  *FML_CURRENT_VERSION' CHANGES.txt|sed 's/.*=//' `
	echo $version
else
	exit 1
fi

exit 0;
