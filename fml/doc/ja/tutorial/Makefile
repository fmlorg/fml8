#
# $FML: Makefile,v 1.2 2001/04/22 16:42:57 fukachan Exp $
#

TARGET_DIR = ../../../../Documentation/ja/tutorial

all: export

html:
	sgmltools -v -b html -j "-v" fml-devel.sgml 2>&1 |\
	uniq

clean:
	find . -type f -print |grep '~' |perl -nple unlink
	rm -fr fml-devel

export: html
	rsync -a fml-devel/@*/ $(TARGET_DIR)/
	rsync -a ../../en/figures/*.gif $(TARGET_DIR)/

