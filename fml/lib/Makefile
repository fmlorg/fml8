all: html

html: _subdir index.ja.html

index.ja.html: [A-Z]*
	../../doc/bin/dir2url.pl > index.ja.html

_subdir: [A-Z]*
	(cd Language; make html)
	(cd FML; make html)
	(cd File; make html)
	(cd IO; make html)
	(cd Mail; make html)
	(cd Tie; make html)
	(cd SQL; make html)
	(cd ErrorMessages; make html)

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../..;make clean)
