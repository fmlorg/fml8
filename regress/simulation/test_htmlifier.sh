#!/bin/sh
#
# $FML: test_htmlifier.sh,v 1.2 2001/10/27 04:52:02 fukachan Exp $
#

./perlcheck HTML/Lite.pm ||exit 1

spool_dir=${spool_dir:-/bakfs/project/fml/fml/ml/fml-help/spool}

rm -fr /tmp/htdocs 
mkdir /tmp/htdocs 

perl -I ../../cpan/lib Mail/HTML/Lite.pm $spool_dir

ls -lRa /tmp/htdocs 
# cat /tmp/htdocs/msg2.html 
# apply readdb.pl /tmp/htdocs/.ht_mhl_*db
