#!/bin/sh
#
# $FML$
#

sh reset_lib.sh ; 

printf "\n\n\n";

makefml digest elena fukachan@sapporo.iij.ad.jp on
sleep 3;

head /var/spool/ml/elena/recipients*

printf "\n\n\n";

makefml digest elena fukachan@sapporo.iij.ad.jp off
sleep 3;

head /var/spool/ml/elena/recipients*


exit 0
