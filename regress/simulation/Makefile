#
# $FML$
#

all: link

clean:
	@ (cd ../..; make clean)
	rm -f __scan__

allclean: clean
	rm -f doc
	rm -f etc
	rm -f lib
	rm -f FML
	rm -f Ticket
	rm -f Process
	rm -f IO
	rm -f Tie
	rm -f Dialect
	rm -f MailingList
	rm -f Mail
	rm -f libexec
	rm -f log
	rm -f File
	rm -f CGI
	rm -f Command
	rm -f SQL
	rm -f ErrorMessages
	rm -f Language
	rm -f doc-devel

scan:
	@ (cd ../..; make scan 2>&1) |tee __scan__ || echo 'nothing changed'
	@ cp __scan__ /tmp/fmlsrc.__scan__

update:
	@ (cd ../..; make update)

check:
	@ (cd ../../fml; make check 2>&1 ) | grep -v OK || echo ''

link:
	rm -f ErrorMessages; ln -s ../../fml/lib/ErrorMessages
	rm -f doc; ln -s ../../fml/doc
	rm -f etc; ln -s ../../fml/etc
	rm -f lib; ln -s ../../fml/lib
	rm -f FML; ln -s ../../fml/lib/FML
	rm -f Ticket; ln -s ../../fml/lib/FML/Ticket
	rm -f CGI; ln -s ../../fml/lib/FML/CGI
	rm -f Process; ln -s ../../fml/lib/FML/Process
	rm -f Command; ln -s ../../fml/lib/FML/Command
	rm -f IO; ln -s ../../fml/lib/IO
	rm -f File; ln -s ../../fml/lib/File
	rm -f SQL; ln -s ../../fml/lib/SQL
	rm -f Tie; ln -s ../../fml/lib/Tie
	rm -f Language; ln -s ../../fml/lib/Language
	rm -f Mail; ln -s ../../fml/lib/Mail
	rm -f libexec; ln -s ../../fml/libexec
	rm -f log; ln -s /var/spool/ml/elena/log
	rm -f doc-devel; ln -s ../../doc/devel/memo doc-devel


diff:
	@ (cd ../..;cvs diff -ub)


test:
	@ echo "* IO::* class test"
	@ apply perl IO/t/*pl
	@ make -f ../base/Makefile

regen:
	(cd ../../fml/etc; make )
	(cd ../../;make doc)

diag:
	env PATH=/usr/pkg/bin:$$PATH make check
