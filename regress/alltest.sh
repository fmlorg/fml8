#!/bin/sh
#
# $Id$
#

(cd ../fml/etc/;sh .gen.sh)
sudo rm -f /etc/fml/main.cf 
sudo rm -f /usr/local/libexec/fml/fmlwrapper
(cd ..; sudo sh INSTALL.sh )
cat example |\
perl -w /usr/local/libexec/fml/fml.pl --params pwd=$PWD /var/spool/ml/elena
	

exit 0

