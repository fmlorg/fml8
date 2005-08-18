#!/bin/sh
#
# $FML: test_digest_offon.sh,v 1.1 2002/12/25 15:35:34 fukachan Exp $
#

sh reset_lib.sh ; 

printf "\n\n\n";

makefml digest elena fukachan@home.fml.org on
sleep 3;

head /var/spool/ml/elena/recipients*

printf "\n\n\n";

makefml digest elena fukachan@home.fml.org off
sleep 3;

head /var/spool/ml/elena/recipients*


exit 0
