#!/bin/sh
#
# $FML: install.sh,v 1.4 2001/10/08 15:41:16 fukachan Exp $
#

(cd ../..; ./configure --sysconfdir=/etc/fml )

# config.cf
sudo -v
echo update /var/spool/ml/elena/config.cf
cp /var/spool/ml/elena/config.cf /var/spool/ml/elena/config.cf.bak
cp config.cf /var/spool/ml/elena/config.cf


(cd ../../fml/etc/;sh .gen.sh)
sudo rm -f /etc/fml/main.cf 
sudo rm -f /usr/local/libexec/fml/loader
(cd ../..; sudo sh INSTALL.sh )

sudo -v
