#!/bin/sh
#
# $FML: .update.sh,v 1.1 2001/10/17 11:58:45 fukachan Exp $
#

base_url=http://cpan.org/modules/

ftp ${base_url}00modlist.long.html

for file in 0*html
do
	txt=`basename $file .html`.txt

	echo ftp ${base_url}$file
	eval ftp ${base_url}$file
	lynx --nolist -dump ${base_url}$file > $txt
done

echo ftp ${base_url}02packages.details.txt.gz
eval ftp ${base_url}02packages.details.txt.gz

echo gunzip -f 02packages.details.txt.gz
eval gunzip -f 02packages.details.txt.gz

exit 0
