all: html

html:	index.ja.html
	(cd Model;make html)

index.ja.html: *pm
	../../../../doc/bin/dir2url.pl > index.ja.html
