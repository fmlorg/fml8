#!/bin/sh
#
# $FML: install.sh,v 1.18 2005/05/27 04:41:13 fukachan Exp $
#

prefix=${FML_EMUL_PREFIX:-/usr/local}
conf_dir=${FML_EMUL_CONF_DIR:-$prefix/etc}
spool_dir=${FML_EMUL_SPOOL_DIR:-/var/spool/ml}

if [ ! -f .this_is_a_test_machine ];then
	echo "touch .this_is_a_test_machine here if you use this script"
	exit 1
fi

(cd ../..; \
	rm -f config.log config.cache ;\
	./configure \
	--prefix=$prefix \
	--with-mlspooldir=$spool_dir \
	--with-warning \
	--with-fmlconfdir=$conf_dir/fml \
	--with-fml-owner=fukachan \
	--with-fml-group=wheel \
	--with-group-writable-ml-home-prefix-map \
	)

echo ""
printenv | grep FML_EMUL_ | awk '{print "\t", $0}'
echo ""

# config.cf
sudo -v

if [ -d /var/spool/ml/elena ];then
	echo updating /var/spool/ml/elena/config.cf
	cp /var/spool/ml/elena/config.cf /var/spool/ml/elena/config.cf.bak
	cp config.cf /var/spool/ml/elena/config.cf
	cp config.ph /var/spool/ml/elena/config.ph
fi

( cd ../../fml/etc/; sh .gen.sh )
sudo rm -f $conf_dir/fml/main.cf 
sudo rm -f $conf_dir/fml/site_default_config.cf 
sudo rm -f /usr/local/libexec/fml/loader

date=`date +%C%y%m%d`
(
	cd ../..;
	echo "7.98.1-$date" > .version
	sudo make install
	rm -f .version
)

sudo -v
