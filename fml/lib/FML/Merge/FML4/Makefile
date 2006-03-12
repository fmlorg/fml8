#
# $FML: Makefile,v 1.1 2004/12/09 03:38:25 fukachan Exp $
#

SH   = sh

PERL = perl

PROG = ../../../../../regress/fml4to8/var_check.sh

CONV = ../../../../../regress/fml4to8/gen_rules.pl 

PRINT_OK = ../../../../../regress/fml4to8/print_ok.pl

all: Rules.pm

Rules.pm: RULES.txt Makefile $(CONV)
	$(PERL) $(CONV) RULES.txt > Rules.pm.new
	perl -cw Rules.pm.new
	test -f Rules.pm.new && mv Rules.pm.new Rules.pm

check:
	@ $(SH) $(PROG) || echo ok

printok: print_ok

print_ok:
	@ echo -n "OK "
	@ $(PERL) $(PRINT_OK) RULES.txt | grep '^OK'    | wc -l
	@ echo -n "   "
	@ $(PERL) $(PRINT_OK) RULES.txt | grep -v '^OK' | wc -l
	@ echo "----------------------------------------"
	@ $(PERL) $(PRINT_OK) RULES.txt | uniq

clean:
	rm -f *~
