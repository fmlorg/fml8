#!/bin/sh
#
# $FML$
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
	FML/Filter/MimeComponent3.pm -c $filter $x
done

exit 0
