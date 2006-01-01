#!/bin/sh
#
# $FML: var_check.sh,v 1.2 2004/12/15 23:16:07 fukachan Exp $
#


echo "// compare cf/MANIFEST and RULES.txt"

# 1. get variable list of cf/MANIFEST
egrep '^[A-Z]' ../../../../../gnu/dist/fml4/cf/MANIFEST |\
awk '{print $1}' |\
sed -e s/:.*$//  |\
sed -e s/:// -e /LOCAL_CONFIG/d -e /^INFO$/d |\
sort | uniq > /tmp/list.manifest

# 2. get variable list of RULES.txt
egrep '^\.if' RULES.txt |\
awk '{print $2}' |\
sort | uniq > /tmp/list.rules

# 2.1. fix variable list.
echo "=> fix list.rules"
echo REJECT_POST_HANDLER    >> /tmp/list.rules
echo REJECT_COMMAND_HANDLER >> /tmp/list.rules
sort -o /tmp/list.rules /tmp/list.rules

# 3. compare variable list
diff -ub /tmp/list.manifest /tmp/list.rules && echo "ok (no difference)"

# 
echo "=> check config_ph.pm"
sed	-e '1,/^sub translate/d' \
	-e '/^#/d' \
	-e '/return.*#/d' \
	-e '/^ *use/d' \
	-e '/type eq /d' \
	-e '/FML::/d' \
	-e '/CODING STYLE/q' config_ph.pm |\
perl -nle 's/([A-Z][0-9A-Z_]+)/print $1/e' |\
egrep -v '^CODING$' |\
sort|\
uniq > /tmp/list.implemented

prog=../../../../../regress/fml4to8/show_rule_as_html.pl 
env RAW_MODE=1 $prog RULES.txt |\
tee /tmp/debug |\
egrep -v '\.ignore|\.unavailable|\.use_fml8_value|\.fml8_default|\+=|\-=| = ' |\
awk '{print $1}' |\
sort |\
uniq > /tmp/list.rules

diff -ub /tmp/list.rules /tmp/list.implemented |\
egrep -v '^ '


exit 0
