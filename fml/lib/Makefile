all: html

html:	_clean index.ja.html

index.ja.html: *.pm
	(cd Dialect; make html)
	(cd FML; make html)
	(cd File; make html)
	(cd IO; make html)
	(cd MailingList; make html)
	(cd Tie; make html)
	../../doc/bin/dir2url.pl > index.ja.html

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../..;make clean)
