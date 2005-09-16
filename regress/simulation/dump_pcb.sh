#!/bin/sh
#
# $FML: dump_pcb.sh,v 1.1 2003/10/29 14:50:54 fukachan Exp $
#

hdr_ja=../../fml/doc/ja/tutorial/internals/PCB.sgml
hdr_en=../../fml/doc/en/tutorial/internals/PCB.sgml
hdr=/tmp/pcb.$$

trap "rm -f $hdr" 0 1 3 15

printf "<para>\n<screen>\n" > $hdr

../style/check_pcb.pl `find FML/ -type f|grep 'pm$'` >> $hdr

printf "</screen>\n</para>\n" >> $hdr

cp -p $hdr $hdr_ja
cp -p $hdr $hdr_en

echo "";
echo "see $hdr";
echo "";

exit 0

