#
# $FML: Makefile,v 1.8 2001/04/24 11:40:37 fukachan Exp $
#

TMP_DIR    = /tmp
TARGET_DIR = ../../../../Documentation/ja/tech
ID         = techtips.html

all: export

html:
	env TMPDIR=$(TMP_DIR) sgmltools -v -b html -j "-v" book.sgml 2>&1 |\
	uniq
	@ perl -i.bak ../.fix_charset.pl book/@*/$(ID)
	@ rm -f book/@*/*.html.bak

clean:
	find . -type f -print |grep '~' |perl -nple unlink
	rm -fr book

export: html
	test -d $(TARGET_DIR) || mkdir $(TARGET_DIR)
	rsync -a book/@*/ $(TARGET_DIR)/
	chmod 755 $(TARGET_DIR)

scan:
	@ cvs -n update 2>&1 |grep -v : || echo ''
