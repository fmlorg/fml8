#!/bin/sh
#
# $FML: emul_digest.sh,v 1.1 2002/11/18 14:38:38 fukachan Exp $
#

find /var/spool/ml/elena/var/mail/queue -type f | perl -nple unlink 

sh reset_lib.sh 

j=`cat /var/spool/ml/elena/seq`
i=`expr $j - 10`
echo $i > /var/spool/ml/elena/seq-digest 

/usr/local/libexec/fml/digest elena@home.fml.org 

sleep 3

exit 0;
