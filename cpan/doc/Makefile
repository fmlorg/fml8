#
# Makefile,v 1.2 2001/05/27 12:09:25 fukachan Exp
#

all: update regen

regen: 98_full_class_name 99_good_modules

99_good_modules: 0*
	./.show_good_modules > 99_good_modules

98_full_class_name: 0*
	perl .conv_classname.pl 00modlist.long.txt > 98_full_class_name

update:
	sh .update.sh
