#!/bin/sh
#
# $FML$
#

today=`date +%C%y%m%d`

if [ ! -d /usr/local/lib/fml/current-$today/ ]; then
	sh install.sh
fi

sudo rsync -C -av lib/ /usr/local/lib/fml/current-$today/ ; 

exit 0
