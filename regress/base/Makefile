#
# $FML: Makefile,v 1.7 2001/09/30 23:07:25 fukachan Exp $
#

PERL = perl -I ../../fml/lib -I ../../cpan/lib -I ../../img/lib

test:
	@ echo "* mime"
	@ $(PERL) ../base/mime.pl
	@ echo "* lock test"
	@ $(PERL) ../base/lock.pl
	@ echo "* checksum test"
	@ $(PERL) ../base/md5.pl
	@ echo "* FML::Date test"
	@ $(PERL) ../base/date2unixtime.pl
	@ echo "* Tie::JournaledFile test"
	@ $(PERL) ../base/journaledfile.pl
	@ echo "* Tie::JournaledDir test"
	@ $(PERL) ../base/journaleddir.pl
	@ echo "* Mail::Message module IO test"
	@ sh ../base/multipart_io.sh
	@ sh ../base/multipart_maker.sh

