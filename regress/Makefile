all: link

clean:
	@ (cd ..;make clean)

scan:
	@ (cd ..;make scan)

update:
	@ (cd ..;make update)

link:
	rm -f lib; ln -s ../fml/lib
	rm -f libexec; ln -s ../fml/libexec
	rm -f log; ln -s /var/spool/ml/elena/log

diff:
	@ (cd ..;cvs diff -ub)
