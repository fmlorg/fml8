#!/bin/sh
#
# $FML$
#

find /var/spool/ml/elena/var/mail/queue -type f | perl -nple unlink 

sh reset_lib.sh 
echo 340 > /var/spool/ml/elena/seq-digest 

/usr/local/libexec/fml/digest elena@home.fml.org 

sleep 3

exit 0;
