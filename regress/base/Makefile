#
# $FML: Makefile,v 1.9 2002/05/11 08:34:52 fukachan Exp $
#

PERL = perl -I ../lib -I ../../fml/lib -I ../../cpan/lib -I ../../img/lib

test:
	@ echo "* miscellaneous functions"
	@ $(PERL) ../base/mime.pl
	@ $(PERL) ../base/lock.pl
	@ $(PERL) ../base/md5.pl
	@ $(PERL) ../base/date2unixtime.pl
	@ $(PERL) ../base/journaledfile.pl
	@ $(PERL) ../base/journaleddir.pl
	@ echo "* Mail::Message module IO test"
	@ sh ../base/multipart_io.sh
	@ sh ../base/multipart_maker.sh

