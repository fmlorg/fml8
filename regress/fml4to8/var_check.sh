#!/bin/sh
#
# $FML$
#


echo "// compare cf/MANIFEST and RULES.txt"


egrep '^[A-Z]' ../../../../../gnu/dist/fml4/cf/MANIFEST |\
awk '{print $1}' |\
sed -e s/:.*$//  |\
sed -e s/:// -e /LOCAL_CONFIG/d -e /^INFO$/d |\
sort | uniq > /tmp/list.manifest

egrep '^\.if' RULES.txt |\
awk '{print $2}' |\
sort | uniq > /tmp/list.rules

# 
echo "=> fix list.rules"
echo REJECT_POST_HANDLER >> /tmp/list.rules
echo REJECT_COMMAND_HANDLER >> /tmp/list.rules
sort -o /tmp/list.rules /tmp/list.rules

diff -ub /tmp/list.manifest /tmp/list.rules && echo "ok (no difference)"

exit 0
