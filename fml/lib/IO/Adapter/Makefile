all: html

html:	_subdir index.ja.html

_subdir:
	(cd MySQL;make html)

index.ja.html: *pm
	../../../../doc/bin/dir2url.pl > index.ja.html
