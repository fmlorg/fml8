#!/bin/sh
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: INSTALL.sh,v 1.63 2003/01/05 02:22:47 fukachan Exp $
#

# Run this from the top-level fml source directory.

PATH=/usr/xpg4/bin:/bin:/usr/bin:/usr/sbin:/usr/etc:/sbin:/etc
umask 022


get_fml_version () {
   if [ -f .version ];then
	fml_version=`cat .version`
   else
	date=`date +%C%y%m%d`
	fml_version=current-${date}
   fi
}

_mkdir () {
	_dir=$1 
	echo mkdiring $_dir; 
	test -d $_dir || mkdir -p $_dir
}


### MAIN ###

# configurations generated by ./configure
. ./config.sh


# cheap diag: check the existence of $owner and $group
is_owner=1
is_group=1
id $owner >/dev/null || is_owner=0

if [ -f /etc/group ];then
	egrep -e "^${group}:" /etc/group >/dev/null || is_group=0
fi

if [ $is_owner = 0 ];then
	echo warning: no such user $owner
	exit 1
fi

if [ $is_group = 0 ];then
	echo warning: no such group $group
	exit 1
fi


# init
get_fml_version
default_config_dir=$config_dir/defaults/$fml_version

# check whether $ml_spool_dir exists or not.
need_fix_ml_spool_dir=0
test -d $ml_spool_dir || need_fix_ml_spool_dir=1

for dir in 	$config_dir \
		$config_dir/defaults \
		$config_dir/defaults/$fml_version \
		$lib_dir	\
		$lib_dir/$fml_version	\
		$libexec_dir	\
		$libexec_dir/$fml_version \
		$data_dir/$fml_version \
		$bindir \
		$ml_spool_dir
do
   test -d $dir || _mkdir $dir
done


if [ ! -f $config_dir/main.cf ];then
	echo creating $config_dir/main.cf
	sed 	-e s@__fml_version__@$fml_version@ \
		-e s@__config_dir__@$config_dir@ \
		fml/etc/main.cf > $config_dir/main.cf
fi

if [ ! -f $config_dir/site_default_config.cf ];then
   echo creating $config_dir/site_default_config.cf
   cp fml/etc/site_default_config.cf $config_dir/site_default_config.cf
fi

if [ ! -f $config_dir/mime_component_filter ];then
   echo creating $config_dir/mime_component_filter
   cp fml/etc/mime_component_filter $config_dir/mime_component_filter
fi

echo updating $default_config_dir/
cp fml/etc/default_config.cf.ja $default_config_dir/default_config.cf
cp fml/etc/config.cf.ja         $default_config_dir/config.cf

for file in include include-ctl include-error aliases \
	postfix_virtual \
	dot_htaccess \
	dot-qmail dot-qmail-admin dot-qmail-ctl dot-qmail-default \
	dot-qmail-request \
	procmailrc
do
   cp fml/etc/$file $default_config_dir/$file
   chmod 644 $default_config_dir/$file
done

cp -pr fml/etc/mtree $default_config_dir/

echo updating $lib_dir/$fml_version/
cp -pr fml/lib/*	$lib_dir/$fml_version/
cp -pr cpan/lib/*	$lib_dir/$fml_version/
cp -pr img/lib/*	$lib_dir/$fml_version/

echo updating $libexec_dir/$fml_version/
cp -pr fml/libexec/*	$libexec_dir/$fml_version/

echo updating $data_dir/$fml_version/
cp -pr fml/share/*	$data_dir/$fml_version/

echo updating ${bindir}/
for prog in 	fml \
		fmladdr fmlalias fmldoc fmlthread fmlconf fmlerror \
		makefml fmlsch fmlhtmlify fmlspool fmlsummary fmlsuper
do
	echo updating ${bindir}/$prog
	cp fml/bin/$prog ${bindir}/$prog.new
	chmod 755 ${bindir}/$prog.new
	mv ${bindir}/$prog.new ${bindir}/$prog
done

PROGRAMS="fml.pl distribute digest command error mead";
PROGRAMS="$PROGRAMS fml makefml makefml.cgi menu.cgi"
PROGRAMS="$PROGRAMS fmlserv fmlconf fmldoc"
PROGRAMS="$PROGRAMS fmlthread fmlthread.cgi"
PROGRAMS="$PROGRAMS fmlsch fmlsch.cgi"
PROGRAMS="$PROGRAMS fmlhtmlify fmlalias fmladdr fmlsummary"
PROGRAMS="$PROGRAMS fmlspool fmlsuper fmlerror"


#
# check loader is upgraded or not
#
loader_replace=0
if [ -f $libexec_dir/loader ];then
   cmp fml/libexec/loader $libexec_dir/loader > /dev/null

   if [ $? != 0 ];then
	echo "warn: loader updated."
	echo -n "  You must upgrade loader. Replace it ? [y/n]"; read answer;

	if [ "X$answer" = "Xy" ];then
		loader_replace=1
	fi   
   fi
fi

#
# new program
#
for x in $PROGRAMS
do
	if [ ! -x $libexec_dir/$x ];then
		loader_replace=1
	fi
done


# 
# install loader
#
if [ ! -f $libexec_dir/loader -o $loader_replace = 1 ];then

   echo install libexec/loader
   cp -p fml/libexec/loader $libexec_dir/loader.new.$$
   mv $libexec_dir/loader.new.$$ $libexec_dir/loader

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
	echo error: run $0 as root
	exit 1
fi

id -un $owner 2>/dev/null || (
	echo warning: user $owner is not defined
)

grep "^${group}:" /etc/group >/dev/null || (
	echo warning: group $group is not defined
)

if [ $need_fix_ml_spool_dir = 1 ]; then
   if [ -d $ml_spool_dir -a -w $ml_spool_dir ]; then
	echo set up the owner of $ml_spool_dir to be $owner
	chown -R $owner:$group $ml_spool_dir
   fi
else
  echo "info: $ml_spool_dir exists. We do not touch it.";
fi

exit 0
