#!/bin/sh
#
# $FML: install.sh,v 1.12 2002/04/22 04:43:58 fukachan Exp $
#

if [ ! -f .this_is_a_test_machine ];then
	echo "touch .this_is_a_test_machine here if you use this script"
	exit 1
fi

(cd ../..; ./configure \
	--with-warning \
	--with-fmlconfdir=/etc/fml \
	--with-fml-owner=fukachan \
	--with-fml-group=wheel \
	)

# config.cf
sudo -v

if [ -d /var/spool/ml/elena ];then
	echo updating /var/spool/ml/elena/config.cf
	cp /var/spool/ml/elena/config.cf /var/spool/ml/elena/config.cf.bak
	cp config.cf /var/spool/ml/elena/config.cf
fi

(cd ../../fml/etc/;sh .gen.sh)
sudo rm -f /etc/fml/main.cf 
sudo rm -f /etc/fml/site_default_config.cf 
sudo rm -f /usr/local/libexec/fml/loader
(cd ../..; sudo ./install.pl fml/etc/install.cf )

sudo -v
