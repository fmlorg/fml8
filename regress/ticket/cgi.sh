#!/bin/sh
#
# $Id$
#

tmp=/tmp/$$
pwd=`pwd`

trap "rm -f $tmp" 0 1 3 15

cd ../.. || exit 1;

echo ml_name=elena |/usr/local/libexec/fml/fmlticket.cgi

exit 0;
