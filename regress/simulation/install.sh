#!/bin/sh
#
# $FML: install.sh,v 1.8 2001/12/11 15:52:12 fukachan Exp $
#

(cd ../..; ./configure \
	--with-fmlconfdir=/etc/fml \
	--with-fml-owner=fukachan \
	--with-fml-group=wheel \
	)

# config.cf
sudo -v
echo updating /var/spool/ml/elena/config.cf
cp /var/spool/ml/elena/config.cf /var/spool/ml/elena/config.cf.bak
cp config.cf /var/spool/ml/elena/config.cf


(cd ../../fml/etc/;sh .gen.sh)
sudo rm -f /etc/fml/main.cf 
sudo rm -f /etc/fml/site_default_config.cf 
sudo rm -f /usr/local/libexec/fml/loader
(cd ../..; sudo sh INSTALL.sh )

sudo -v
