#
# $FML: Makefile,v 1.7 2001/04/27 05:10:26 fukachan Exp $
#

PERL = perl -w -I ../img/lib -I ../cpan/lib -I ./lib -I ./libexec

all: test

scan:
	@ cvs -n update 2>&1 |grep -v : || echo ''

update:
	@ cvs update -dAP|grep -v : || echo ''

check:
	@ for x in `find lib* -type f -print|grep pm|grep -v CPAN` ; do $(PERL) -c $$x || echo '' ;done
	@ for x in libexec/loader ; do $(PERL) -c $$x || echo '' ;done

clean:
	@ find . |grep '~' |perl -nple unlink
