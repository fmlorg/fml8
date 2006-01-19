#!/bin/sh 
#
# $FML$
#

dir=`pwd`
msg=`pwd`/../testmails/text=plain

. $dir/config.sh

cd $ml_home_dir || exit 1

pwd

$dir/../message/scramble.pl $msg | $exec_prefix/fml.pl $ml_home_dir

exit 0;
