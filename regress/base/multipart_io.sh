#!/bin/sh

dir=`dirname $0`

tmp=/tmp/buf$$

sed -n '1,/^$/p' $dir/msg_mp > $tmp
perl $dir/multipart_io.pl   >> $tmp

diff -ub $dir/msg_mp $tmp && echo ok || echo fail

exit 0;
