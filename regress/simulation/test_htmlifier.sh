#!/bin/sh
#
# $FML$
#

./perlcheck HTML/Lite.pm ||exit 1

x=spool/? 

rm -fr /tmp/htdocs 
mkdir /tmp/htdocs 
perl -I ../../cpan/lib Mail/HTML/Lite.pm \
	/bakfs/project/fml/fml/ml/fml-help/spool
ls -lRa /tmp/htdocs 
# cat /tmp/htdocs/msg2.html 
# apply readdb.pl /tmp/htdocs/.ht_mhl_*db
