all: anal

anal:
	@ find . | sort | grep -v CVS | sed 's@./@@'

html:	index.ja.html

index.ja.html: *.pm
	../../../../doc/bin/dir2url.pl > index.ja.html

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../../../..;make clean)
