#!/bin/sh
#
# $Id$
#

date=$1

cd ../../ || exit 1

cvs diff -ub -D $date 2>&1 |\
perl -nle 's/no revision.*in file\s+(\S+)/print $1/e;\
	s/Index:\s+(\S+)/print $1/e;'

exit 0;
