#!/bin/sh
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

# Run this from the top-level fml source directory.

PATH=/bin:/usr/bin:/usr/sbin:/usr/etc:/sbin:/etc
umask 022

### configurations ###
date=`date +%C%y%m%d`
version=current-${date}
prefix_dir=/usr/local
config_dir=/etc/fml
libexec_dir=$prefix_dir/libexec/fml
lib_dir=$prefix_dir/lib/fml


# ml spool
ml_spool_dir=/var/spool/ml

# owner of /var/spool/ml
owner=fukachan

######################


_mkdir () {
	local dir=$1 
	echo mkdir $dir; 
	test -d $dir || mkdir $dir
}


for dir in 	$config_dir \
		$config_dir/defaults \
		$config_dir/defaults/$version \
		$lib_dir	\
		$lib_dir/$version	\
		$libexec_dir	\
		$libexec_dir/$version \
		$ml_spool_dir
do
   test -d $dir || _mkdir $dir
done


if [ ! -f $config_dir/main.cf ];then
	echo create $config_dir/main.cf
	sed 	-e s@__version__@$version@ \
		-e s@__config_dir__@$config_dir@ \
		-e s@__prefix_dir__@$prefix_dir@ \
		fml/etc/main.cf > $config_dir/main.cf
fi

echo update $config_dir/defaults/$version/
cp fml/etc/default_config.cf.ja $config_dir/defaults/$version/default_config.cf

echo update $lib_dir/$version/
cp -pr fml/lib/*	$lib_dir/$version/
cp -pr cpan/lib/*	$lib_dir/$version/

echo update $libexec_dir/$version/
cp -pr fml/libexec/*	$libexec_dir/$version/

if [ ! -f $libexec_dir/fmlwrapper ];then

   echo install libexec/fmlwrapper
   cp -pr fml/libexec/fmlwrapper    $libexec_dir/

   echo install libexec/Standalone.pm
   cp -pr fml/libexec/Standalone.pm $libexec_dir/

   (
	cd $libexec_dir/

	echo -n "   link fmlwrapper to: "
	for x in fml.pl distribute command fmlserv mead
	do
		rm -f $x
		ln -s fmlwrapper $x && echo -n "$x "
	done
	echo ""
   )
fi

if [ -d $ml_spool_dir ]; then
	echo set up the owner of $ml_spool_dir to be $owner
	chown -R $owner $ml_spool_dir
fi

exit 0
