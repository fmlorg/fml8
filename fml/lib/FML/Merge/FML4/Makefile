#
# $FML$
#

SH   = sh

PERL = perl

PROG = ../../../../../regress/fml4to8/var_check.sh

CONV = ../../../../../regress/fml4to8/gen_rules.pl 


all: Rules.pm

Rules.pm: RULES.txt Makefile $(CONV)
	$(PERL) $(CONV) RULES.txt > Rules.pm.new
	perl -cw Rules.pm.new
	test -f Rules.pm.new && mv Rules.pm.new Rules.pm

check:
	@ $(SH) $(PROG) || echo ok

clean:
	rm -f *~
