#!/bin/sh
#
# $FML$
#

echo "# reset message-id database"
find /var/spool/ml/elena/var/db/message_id/ | perl -nple unlink ; 

echo "# reset library"
sh reset_lib.sh ; 

printf "\n%s\n\n" "# start emulation";

/usr/local/libexec/fml/fetchfml elena@home.fml.org --article-post

/usr/local/libexec/fml/fetchfml elena@home.fml.org --command-mail

/usr/local/libexec/fml/fetchfml elena@home.fml.org --error

exit 0;
