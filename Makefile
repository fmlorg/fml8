#
# $FML: Makefile,v 1.9 2001/04/24 03:11:20 fukachan Exp $
#

CONV = doc/bin/text2html.pl

all: test

install:
	sh INSTALL.sh

scan:
	@ cvs -n update 2>&1 |grep -v : || echo ''

update:
	@ cvs update -dAP|grep -v : || echo ''

clean:
	@ find . |grep '~' |perl -nple unlink

doc: html

html: _html tutorial

_html:
	@ (cd fml/lib/;make html)
	@ (cd fml/libexec/;make html)
	@ (cd fml/etc/;make html)
	@ (cd cpan/dist/;make html)
	@ $(CONV) 00_README.ja.txt > fml/doc/install.ja.html

tutorial:
	@ (cd fml/doc/ja/tutorial; make ; make clean)
