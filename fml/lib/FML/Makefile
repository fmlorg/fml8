all: anal

anal:
	@ find . | sort | grep -v CVS | sed 's@./@@'

html:	index.ja.html
	(cd Header; make html)
	(cd Process; make html)
	(cd Ticket; make html)
	(cd CGI; make html)

index.ja.html: *.pm [A-Z]*
	../../../doc/bin/dir2url.pl > index.ja.html

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../../..;make clean)
