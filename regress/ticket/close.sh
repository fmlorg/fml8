#!/bin/sh
#
# $FML: close.sh,v 1.1 2001/02/16 11:31:11 fukachan Exp $
#

tmp=/tmp/$$
pwd=`pwd`

trap "rm -f $tmp" 0 1 3 15

cd ../.. || exit 1;

/usr/local/libexec/fml/fmlticket \
		--params pwd=$PWD \
		-c $pwd/main.cf \
		-R open \
		close /var/spool/ml/elena $*

exit 0;
