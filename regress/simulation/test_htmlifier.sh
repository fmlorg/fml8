#!/bin/sh
#
# $FML: test_htmlifier.sh,v 1.5 2003/08/09 01:39:54 fukachan Exp $
#

./perlcheck Mail/Message/ToHTML.pm ||exit 1

spool_dir=${spool_dir:-/bakfs/project/fml/fml/ml/fml-help/spool}

rm -fr /tmp/htdocs /tmp/elena
mkdir /tmp/htdocs 

perl -I ../../fml/lib -I ../../img/lib -I ../../cpan/lib \
	Mail/Message/ToHTML.pm $spool_dir

ls -lRa /tmp/htdocs 
# cat /tmp/htdocs/msg2.html 
# apply readdb.pl /tmp/htdocs/.ht_mhl_*db
