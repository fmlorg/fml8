#!/bin/sh
#
# $Id$
#

cat example |\
perl -w /usr/local/libexec/fml/fml.pl -c $PWD/main.cf /var/spool/ml/elena

exit 0

