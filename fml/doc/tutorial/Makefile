all: html

html:
	sgmltools -v -b html -j "-v" fml-devel.sgml 2>&1 |\
	uniq

clean:
	find . -type f -print |grep '~' |perl -nple unlink
	rm -fr fml-devel

export: html
	rsync -av fml-devel/@*/ ../../../Documentation/ja/tutorial/

