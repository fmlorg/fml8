all: link

clean:
	@ (cd ../..;make clean)

scan:
	@ (cd ../..;make scan)

update:
	@ (cd ../..;make update)

link:
	rm -f doc; ln -s ../../fml/doc
	rm -f etc; ln -s ../../fml/etc
	rm -f lib; ln -s ../../fml/lib
	rm -f FML; ln -s ../../fml/lib/FML
	rm -f Ticket; ln -s ../../fml/lib/FML/Ticket
	rm -f Process; ln -s ../../fml/lib/FML/Process
	rm -f IO; ln -s ../../fml/lib/IO
	rm -f Tie; 
	rm -f Dialect; ln -s ../../fml/lib/Dialect
	rm -f MailingList; ln -s ../../fml/lib/MailingList
	rm -f libexec; ln -s ../../fml/libexec
	rm -f log; ln -s /var/spool/ml/elena/log

diff:
	@ (cd ../..;cvs diff -ub)


test:
	@ echo "* IO::* class test"
	@ apply perl IO/t/*pl
