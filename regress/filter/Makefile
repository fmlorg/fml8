#
# $FML: Makefile,v 1.1.1.1 2001/08/19 14:51:46 fukachan Exp $
#

PERL = perl

TARGETS = ../filter/t/0* ../testmails/text=* ../testmails/multipart=mixed*

all: check

check:
	$(PERL) ../filter/check.pl $(TARGETS)

mesg_analyze:
	@ echo "* check BodyCheck basic functions"
	../filter/bodycheck.pl ../testmails/text=* \
		../testmails/multipart=*
