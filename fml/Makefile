PERL = perl -w -I ../cpan/lib -I ./lib -I ./libexec

all: test

scan:
	@ cvs -n update 2>&1 |grep -v : || echo ''

update:
	@ cvs update -dAP|grep -v : || echo ''

test: test2 

test1:
	@ cat w/example |\
	  perl -w libexec/distribute etc/default_config.cf etc/config.cf

test2:
	@ cat w/example |\
	  perl -w libexec/fml.pl /var/spool/ml/elena

test3:
	@ echo '-- test in the case where Socket6 fail'
	@ cat w/example |\
	  /usr/pkg/bin/perl -w libexec/fml.pl /var/spool/ml/elena

check:
	@ for x in `find lib* -type f -print|grep pm|grep -v CPAN` ; do $(PERL) -c $$x || echo '' ;done
	@ for x in libexec/loader ; do $(PERL) -c $$x || echo '' ;done

clean:
	@ find . |grep '~' |perl -nple unlink

link:
	rm -f FML MailingList IO 
	ln -s lib/fml5/FML .
	ln -s lib/fml5/MailingList .
	ln -s lib/fml5/IO .
	(cd libexec; ln -s loader fml.pl) 
