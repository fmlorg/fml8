#!/bin/sh
#
# $FML$
#

echo "";echo "// find Log*()";echo "";
egrep -r 'Log\(|LogWarn\(|LogError\(' FML |\
egrep -v 'FML/Log.pm|Process/Kernel.pm|Filter/MimeComponent.pm' |\
grep pm: |\
sed s@//@/@g

echo "";echo "// check_log ";echo "";
perl ../style/check_log.pl ` find FML/ -type f |grep 'pm$' ` 2>&1 |\
egrep -v '^ok' |\
egrep -v 'Log.pm|MimeComponent.pm'

exit 0
