#!/bin/sh
#
# $Id$
#

tmp=/tmp/$$
pwd=`pwd`

trap "rm -f $tmp" 0 1 3 15

cd ../.. || exit 1;

echo | /usr/local/libexec/fml/fmlticket.cgi elena $*

exit 0;
