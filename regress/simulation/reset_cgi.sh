#!/bin/sh
#
# $FML$
#

sh reset_lib.sh
makefml --force newml elena
rm -f $HOME/public_html/cgi-bin/fml/fml.org/.htaccess

egrep -v '^#' $HOME/public_html/cgi-bin/fml/fml.org/admin/menu.cgi |head -30

exit 0
