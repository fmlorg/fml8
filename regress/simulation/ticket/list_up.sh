#!/bin/sh
#
# $Id$
#

pwd=`pwd`

cd ../.. || exit 1;

exec /usr/local/libexec/fml/fmlticket \
		--params pwd=$PWD \
		-c $pwd/main.cf \
		-R open \
		list /var/spool/ml/elena


