#
# $FML: Makefile,v 1.5 2001/04/23 11:40:44 fukachan Exp $
#

TMP_DIR    = /tmp
TARGET_DIR = ../../../../Documentation/ja/tutorial

all: export

html:
	env TMPDIR=$(TMP_DIR) sgmltools -v -b html -j "-v" fml-devel.sgml 2>&1 |\
	uniq
	@ perl -i.bak .fix_charset.pl fml-devel/@*/fml-devel.html
	@ rm -f fml-devel/@*/fml-devel.html.bak

clean:
	find . -type f -print |grep '~' |perl -nple unlink
	rm -fr fml-devel

export: html
	test -d  $(TARGET_DIR) || mkdir $(TARGET_DIR)
	rsync -a fml-devel/@*/ $(TARGET_DIR)/
	rsync -a ../../en/figures/*.gif $(TARGET_DIR)/

