all: anal

anal:
	@ find . | sort | grep -v CVS | sed 's@./@@'

html:	index.ja.html

index.ja.html: *.pm
	(cd Delivery; make html)
	(cd Bounce; make html)
	(cd Message; make html)
	../../../doc/bin/dir2url.pl > index.ja.html

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../../..;make clean)
