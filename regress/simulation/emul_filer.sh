#!/bin/sh
#
# $FML: emul_filer.sh,v 1.1 2003/01/09 04:04:09 fukachan Exp $
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
