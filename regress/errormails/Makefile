#
# $FML$
#

BOUNCE = perl -I ../../fml/lib -I ../../cpan/lib ../message/bounce.pl 

all:check

check: [a-z]*
	@ $(BOUNCE) [a-z]*[a-z0-9] |\
	grep '^#' | rev | sort | rev | sed 's/^# *//'

_check: [a-z]*
	@ $(BOUNCE) [a-z]*[a-z0-9]

