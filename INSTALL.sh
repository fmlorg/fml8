#!/bin/sh
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: INSTALL.sh,v 1.28 2001/11/05 12:26:37 fukachan Exp $
#

# Run this from the top-level fml source directory.

PATH=/bin:/usr/bin:/usr/sbin:/usr/etc:/sbin:/etc
umask 022

### configurations ###
default_prefix=/usr/local
config_dir=/etc/fml
libexec_dir=$default_prefix/libexec/fml
lib_dir=$default_prefix/lib/fml


# ml spool
ml_spool_dir=/var/spool/ml

# owner of /var/spool/ml
owner=fml

######################

get_fml_version () {
   if [ -f .version ];then
	fml_version=`cat .version`
   else
	date=`date +%C%y%m%d`
	fml_version=current-${date}
   fi
}

_mkdir () {
	local dir=$1 
	echo mkdir $dir; 
	test -d $dir || mkdir -p $dir
}


### MAIN ###

get_fml_version
default_config_dir=$config_dir/defaults/$fml_version


for dir in 	$config_dir \
		$config_dir/defaults \
		$config_dir/defaults/$fml_version \
		$lib_dir	\
		$lib_dir/$fml_version	\
		$libexec_dir	\
		$libexec_dir/$fml_version \
		$ml_spool_dir
do
   test -d $dir || _mkdir $dir
done


if [ ! -f $config_dir/main.cf ];then
	echo create $config_dir/main.cf
	sed 	-e s@__fml_version__@$fml_version@ \
		-e s@__config_dir__@$config_dir@ \
		-e s@__default_prefix__@$default_prefix@ \
		fml/etc/main.cf > $config_dir/main.cf
fi

echo update $default_config_dir/
cp fml/etc/default_config.cf.ja $default_config_dir/default_config.cf
cp fml/etc/config.cf.ja $default_config_dir/config.cf

echo update $lib_dir/$fml_version/
cp -pr fml/lib/*	$lib_dir/$fml_version/
cp -pr cpan/lib/*	$lib_dir/$fml_version/
cp -pr img/lib/*	$lib_dir/$fml_version/

echo update $libexec_dir/$fml_version/
cp -pr fml/libexec/*	$libexec_dir/$fml_version/

echo update /usr/local/bin/
for prog in fmldoc fmlthread fmlconf makefml fmlsch fmlhtmlify
do
	echo update /usr/local/bin/$prog
	cp fml/bin/$prog /usr/local/bin/$prog.new
	mv /usr/local/bin/$prog.new /usr/local/bin/$prog
done

PROGRAMS="fml.pl distribute command ";
PROGRAMS="$PROGRAMS fmlserv mead fmlconf fmldoc"
PROGRAMS="$PROGRAMS fmlthread fmlthread.cgi"
PROGRAMS="$PROGRAMS makefml makefml.cgi"
PROGRAMS="$PROGRAMS fmlsch fmlsch.cgi"
PROGRAMS="$PROGRAMS fmlhtmlify"

if [ ! -f $libexec_dir/loader ];then

   echo install libexec/loader
   cp -pr fml/libexec/loader    $libexec_dir/

   echo install libexec/Standalone.pm
   cp -pr fml/libexec/Standalone.pm $libexec_dir/

   (
	cd $libexec_dir/
	i=0

	echo -n "   link loader to: "
	for x in $PROGRAMS
	do
		rm -f $x
		ln -s loader $x && echo -n "$x "

		i=`expr $i + 1`
		if [ $i -ge 6 ];then
			echo ""
			echo -n "                   "
			i=0
		fi
	done
	echo ""
   )
fi

iam=`id -un`

if [ "X$iam" != Xroot ];then
	exit 1
fi

id -un $owner || exit 1

exit 0;

if [ -d $ml_spool_dir -a -w $ml_spool_dir ]; then
	echo set up the owner of $ml_spool_dir to be $owner
	chown -R $owner $ml_spool_dir
fi

exit 0
