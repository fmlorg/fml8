#
# $FML: Makefile,v 1.35 2001/05/20 13:19:59 fukachan Exp $
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
	rm -f Language
	rm -f doc-devel
	rm -f tutorial

scan:
	@ (cd ../..; make scan 2>&1) |tee __scan__ || echo 'nothing changed'
	@ cp __scan__ /tmp/fmlsrc.__scan__

update:
	@ (cd ../..; make update)

check:
	@ (cd ../../fml; make check 2>&1 ) | grep -v OK || echo ''

link:
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
	rm -f doc-devel; ln -s ../../cpan/doc doc-devel
	rm -f tutorial; ln -s ../../fml/doc/ja/tutorial tutorial


diff:
	@ (cd ../..;cvs diff -ub)


test:
	@ echo "* IO::* class test"
	@ apply perl IO/t/*pl
	@ test -d /tmp/a || mkdir /tmp/a
	@ make -f ../base/Makefile
	@ echo "* errormails"
	@ (cd ../errormails; make check)

regen:
	(cd ../../fml/etc; make )

diag:
	env PATH=/usr/pkg/bin:$$PATH make check
