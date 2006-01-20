#!/bin/sh 
#
# $FML: emul_post.sh,v 1.1 2006/01/19 14:23:21 fukachan Exp $
#

dir=`pwd`
msg=${1:-`pwd`/../testmails/text=plain}

. $dir/config.sh

cd $ml_home_dir || exit 1

pwd

$dir/../message/scramble.pl $msg | $exec_prefix/fml.pl $ml_home_dir

exit 0;
