#
# $FML: Makefile,v 1.3 2001/04/23 03:49:48 fukachan Exp $
#

TMP_DIR    = 
TARGET_DIR = ../../../../Documentation/ja/tutorial

all: export

html:
	env TMPDIR=$(TMP_DIR) sgmltools -v -b html -j "-v" fml-devel.sgml 2>&1 |\
	uniq

clean:
	find . -type f -print |grep '~' |perl -nple unlink
	rm -fr fml-devel

export: html
	rsync -a fml-devel/@*/ $(TARGET_DIR)/
	rsync -a ../../en/figures/*.gif $(TARGET_DIR)/

