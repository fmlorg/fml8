#
# $FML: Makefile,v 1.3 2001/05/30 14:34:41 fukachan Exp $
#

all: anal

anal:
	@ find . | sort | grep -v CVS | sed 's@./@@'

html:	index.ja.html

index.ja.html: *.pm loader.in
	../../fml/utils/bin/dir2url.pl > index.ja.html

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../..;make clean)

