#
# $FML: Makefile,v 1.2 2001/10/14 22:22:13 fukachan Exp $
#

PERL = perl

TARGETS = ../filter/t/0* ../testmails/text=* ../testmails/multipart=mixed*

all: check check2

check:
	$(PERL) ../filter/check.pl $(TARGETS)

check2:
	$(PERL) ../filter/check2.pl $(TARGETS)

mesg_analyze:
	@ echo "* check BodyCheck basic functions"
	../filter/bodycheck.pl ../testmails/text=* \
		../testmails/multipart=*
