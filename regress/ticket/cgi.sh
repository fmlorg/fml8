#!/bin/sh
#
# $FML: cgi.sh,v 1.3 2001/03/25 08:27:07 fukachan Exp $
#

tmp=/tmp/$$
pwd=`pwd`

trap "rm -f $tmp" 0 1 3 15

cd ../.. || exit 1;

echo ml_name=elena |/usr/local/libexec/fml/fmlticket.cgi

exit 0;
