#!/bin/sh
#
# $Id$
#

cat example |\
perl -w /usr/local/libexec/fml/fml.pl \
	--params pwd=$PWD \
	-c $PWD/main.cf \
	/var/spool/ml/elena

exit 0

