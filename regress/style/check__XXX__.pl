#!/bin/sh
#
# $FML$
#

tmp=/tmp/buffer$$
trap "rm -f $tmp" 0 1 3 15

cd ../.. || exit 1

egrep -r '__[A-Z]' fml |\
egrep -v 'config.guess|configure|CVS|__template|__FILE__|__END__|__DATA__'
