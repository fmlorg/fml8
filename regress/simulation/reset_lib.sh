#!/bin/sh
#
# $FML: reset_lib.sh,v 1.1 2003/02/11 13:23:14 fukachan Exp $
#

today=`date +%C%y%m%d`

version=7.98.1

if [ ! -d /usr/local/lib/fml/$version-$today/ ]; then
	sh install.sh
fi

sudo rsync -C -av lib/ /usr/local/lib/fml/$version-$today/ ; 

exit 0
