#!/bin/sh
#
# $Id$
#

cat example |\
perl -w /usr/local/libexec/fml/fmlwrapper \
	--params pwd=$PWD \
	-c $PWD/main.cf \
	/var/spool/ml/elena

exit 0

