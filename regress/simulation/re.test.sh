#!/bin/sh
#
# $Id$
#

pwd=`pwd`

cd ../.. || exit 1
pwd
cat $pwd/example.re |\
perl -w fml/libexec/loader \
	--params pwd=$PWD \
	-c $pwd/main.cf \
	/var/spool/ml/elena

echo "-- exit code: $?"

exit 0

