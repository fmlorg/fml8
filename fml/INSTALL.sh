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
version=5.000
prefix_dir=/usr/local
config_dir=/etc/fml
libexec_dir=$prefix_dir/libexec/fml
lib_dir=$prefix_dir/lib/fml
######################

if [ ! -d $config_dir ];then
	echo "I cannot find $config_dir"
	exit 1
fi

for dir in $config_dir/defaults $config_dir/defaults/$version
do
   test -d $dir || mkdir $dir
done

cp etc/main.cf           $config_dir/main.cf
cp etc/default_config.cf $config_dir/defaults/$version

echo debug now ...
ln -s $PWD/libexec $libexec_dir/$version 
ln -s $PWD/lib $lib_dir/$version

echo "please link"
echo "% ln -s $PWD/etc/config.cf /var/spool/ml/elena/config.cf"

exit 0
