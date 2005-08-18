#!/bin/sh
#
# $FML: emul_filer.sh,v 1.2 2003/10/15 00:40:45 fukachan Exp $
#

if [ -f mime_component_filter ];then
	filter=mime_component_filter
else 
	filter=etc/mime_component_filter
fi

echo use $filter as filter rules.

for x in $*
do
   perl -I ../../fml/lib -I ../../cpan/lib \
	FML/Filter/MimeComponent.pm -c $filter $x
done

exit 0
