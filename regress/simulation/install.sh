#!/bin/sh
#
# $FML: install.sh,v 1.5 2001/11/12 14:38:00 fukachan Exp $
#

(cd ../..; ./configure --sysconfdir=/etc/fml --with-fml-owner=fukachan )

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
