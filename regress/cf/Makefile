#
# $FML: Makefile,v 1.2 2002/07/22 09:38:39 fukachan Exp $
#

PERL   = perl -I ../lib -I ../../fml/lib -I ../../cpan/lib 

test:
	@ echo "* FML::Config overload test:"
	@ $(PERL) ../cf/test.overload.pl ../cf/default.cf ../cf/1.cf
	@ $(PERL) ../cf/read_only.pl
