#!/bin/sh
#
# $FML: install.sh,v 1.15 2004/06/24 11:03:59 fukachan Exp $
#

prefix=/usr/local
conf_dir=$prefix/etc

if [ ! -f .this_is_a_test_machine ];then
	echo "touch .this_is_a_test_machine here if you use this script"
	exit 1
fi

(cd ../..; \
	rm -f config.log config.cache ;\
	./configure \
	--prefix=$prefix \
	--with-warning \
	--with-fmlconfdir=$conf_dir/fml \
	--with-fml-owner=fukachan \
	--with-fml-group=wheel \
	--with-group-writable-ml-home-prefix-map \
	)

# config.cf
sudo -v

if [ -d /var/spool/ml/elena ];then
	echo updating /var/spool/ml/elena/config.cf
	cp /var/spool/ml/elena/config.cf /var/spool/ml/elena/config.cf.bak
	cp config.cf /var/spool/ml/elena/config.cf
fi

( cd ../../fml/etc/; sh .gen.sh )
sudo rm -f $conf_dir/fml/main.cf 
sudo rm -f $conf_dir/fml/site_default_config.cf 
sudo rm -f /usr/local/libexec/fml/loader
( cd ../..; sudo make install )

sudo -v
