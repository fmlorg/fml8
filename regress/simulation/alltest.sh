#!/bin/sh
#
# $FML: alltest.sh,v 1.4 2001/04/08 07:21:59 fukachan Exp $
#

(cd ../../fml/etc/;sh .gen.sh)
sudo rm -f /etc/fml/main.cf 
sudo rm -f /usr/local/libexec/fml/loader
(cd ../..; sudo sh INSTALL.sh )

../message/scramble.pl ../testmails/text=plain |\
perl -w /usr/local/libexec/fml/fml.pl --params pwd=$PWD /var/spool/ml/elena
	
exit 0

