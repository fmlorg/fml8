#!/bin/sh
#
# $FML$
#

hdr=../../fml/doc/ja/tutorial/internals/CURPROC.sgml

_script=emul_post.sh

env debug=101 sh $_script >  /tmp/x0

printf "<para>\n<screen>\n" > $hdr

perl -nle 'print if /CURPROC_BEGIN/ .. /CURPROC_END/' /tmp/x0 |\
egrep -v '^CURPROC_' |\
tee -a $hdr

printf "</screen>\n</para>\n" >> $hdr

echo "";
echo "see $hdr";
echo "";

exit 0
