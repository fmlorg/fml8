PERL = perl -I ../../fml/lib -I ../../cpan/lib

test:
	@ echo "* mime"
	@ $(PERL) ../base/mime.pl
	@ echo "* lock test"
	@ $(PERL) ../base/lock.pl
	@ echo "* checksum test"
	@ $(PERL) ../base/md5.pl
	@ echo "* multipart operations test"
	@ sh ../base/multipart_io.sh
	@ sh ../base/multipart_maker.sh

