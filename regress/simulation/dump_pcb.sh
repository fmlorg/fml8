#!/bin/sh
#
# $FML: dump_curproc.sh,v 1.1 2003/03/14 04:11:52 fukachan Exp $
#

hdr=../../fml/doc/ja/tutorial/internals/PCB.sgml

printf "<para>\n<screen>\n" > $hdr

../style/check_pcb.pl `find FML/ -type f|grep 'pm$'` >> $hdr

printf "</screen>\n</para>\n" >> $hdr

echo "";
echo "see $hdr";
echo "";

exit 0

