#!/bin/sh
#
# $FML: .gen.sh,v 1.11 2002/09/14 01:22:20 fukachan Exp $
#

tmp=default_config.cf.xx.$$

trap "rm -f $tmp" 0 1 3 15

(
	cat <<_EOF_
#
# list of available hooks
#

_EOF_

	egrep -r 'config.*get_hook' ../lib |\
	egrep -v '~:|bak:' |\
	sed 	-e 's/^.*get_hook(//' \
		-e 's/);//' \
		-e "s@'@@g" \
		-e 's/ *//g' |\
	grep -v START_HOOK |\
	sort -t _ |\
	sed -e 's/^/# $/' -e 's/$/ = q{ 1;};/'
)  > src/hooks.cf

for lang in ja en
do
	test -f $tmp || rm -f $tmp

	cat src/list.cf | while read file
	do
		cat src/config.cf.$lang/$file >> $tmp
		echo "" >> $tmp
	done

	mv $tmp default_config.cf.$lang.in

	if [ -f default_config.cf.$lang.in ];then
		echo creating default_config.cf.$lang.in
	fi
done

exit 0
