#
# $FML: Makefile,v 1.10 2006/01/24 11:31:13 fukachan Exp $
#

PERL = perl -I ../lib -I ../../fml/lib -I ../../cpan/lib -I ../../img/lib

test: _base_test _message_test

_base_test:
	@ $(PERL) ../base/mime.pl
	@ $(PERL) ../base/lock.pl
	@ $(PERL) ../base/md5.pl
	@ $(PERL) ../base/date2unixtime.pl
	@ $(PERL) ../base/journaledfile.pl
	@ $(PERL) ../base/journaleddir.pl

_message_test:
	@ echo "* Mail::Message module test"
	@ sh ../base/multipart_io.sh
	@ sh ../base/multipart_maker.sh

