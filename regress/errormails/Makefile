#
# $FML: Makefile,v 1.2 2001/07/31 14:03:39 fukachan Exp $
#

PERL   = perl -I ../lib -I ../../fml/lib -I ../../cpan/lib 
BOUNCE = $(PERL) ../message/bounce.pl 

all:check

check: [a-z]*
	@ $(BOUNCE) [a-z]*[a-z0-9] |\
	grep '^#' | rev | sort | rev | sed 's/^# *//'

_check: [a-z]*
	@ $(BOUNCE) [a-z]*[a-z0-9]

