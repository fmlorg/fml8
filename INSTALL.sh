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
date=`date +%C%y%d%m`
version=current-${date}
prefix_dir=/usr/local
config_dir=/etc/fml
libexec_dir=$prefix_dir/libexec/fml
lib_dir=$prefix_dir/lib/fml
######################

_mkdir () {
	local dir=$1 
	echo mkdir $dir; test -d $dir || mkdir $dir
}


for dir in 	$config_dir \
		$config_dir/defaults \
		$config_dir/defaults/$version \
		$lib_dir	\
		$lib_dir/$version	\
		$libexec_dir	\
		$libexec_dir/$version
do
   test -d $dir || _mkdir $dir
done


if [ ! -f $config_dir/main.cf ];then
	sed 	-e s@__version__@$version@ \
		-e s@__config_dir__@$config_dir@ \
		-e s@__prefix_dir__@$prefix_dir@ \
		fml/etc/main.cf > $config_dir/main.cf
fi

cp fml/etc/default_config.cf $config_dir/defaults/$version

cp -pr fml/lib/*	$lib_dir/$version
cp -pr cpan/lib/*	$lib_dir/$version
cp -pr fml/libexec/*	$libexec_dir/$version

if [ ! -f $libexec_dir/fmlwrapper ];then

   cp -pr fml/libexec/fmlwrapper    $libexec_dir/
   cp -pr fml/libexec/Standalone.pm $libexec_dir/
   (
	cd $libexec_dir/
	ln -s fmlwrapper fml.pl
	ln -s fmlwrapper distribute
	ln -s fmlwrapper command
	ln -s fmlwrapper fmlserv
	ln -s fmlwrapper mead
   )
fi


exit 0
