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

html:
	@ (cd fml/lib/;make html)
	@ (cd cpan/dist/;make html)

