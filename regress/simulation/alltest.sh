#!/bin/sh
#
# $FML$
#

(cd ../../fml/etc/;sh .gen.sh)
sudo rm -f /etc/fml/main.cf 
sudo rm -f /usr/local/libexec/fml/loader
(cd ../..; sudo sh INSTALL.sh )

cat ../testmails/text=plain |\
perl -w /usr/local/libexec/fml/fml.pl --params pwd=$PWD /var/spool/ml/elena
	
exit 0

