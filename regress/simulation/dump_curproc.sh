#!/bin/sh
#
# $FML: dump_curproc.sh,v 1.1 2003/03/14 04:11:52 fukachan Exp $
#

hdr=/tmp/buf$$
hdr1=../../fml/doc/ja/tutorial/internals/CURPROC.sgml
hdr2=../../fml/doc/en/tutorial/internals/CURPROC.sgml

trap "rm -f $hdr" 0 1 3 15

_script=emul_post.sh

env debug=101 sh $_script >  /tmp/x0

printf "<para>\n<screen>\n" > $hdr

perl -nle 'print if /CURPROC_BEGIN/ .. /CURPROC_END/' /tmp/x0 |\
egrep -v '^CURPROC_' |\
tee -a $hdr

printf "</screen>\n</para>\n" >> $hdr

cp $hdr $hdr1
cp $hdr $hdr2

echo "";
echo "see $hdr";
echo "";

exit 0
