#
# $FML: Makefile,v 1.47 2001/10/17 10:26:51 fukachan Exp $
#

all: link

clean:
	@ (cd ../..; make clean)
	rm -f __scan__

allclean: clean clean_link

clean_link:
	for file in * ; do  test -h $$file && rm -f $$file || true ; done

scan:
	@ (cd ../..; make scan 2>&1) |tee __scan__ || echo 'nothing changed'
	@ cp __scan__ /tmp/fmlsrc.__scan__

update:
	@ (cd ../..; make update)

check:
	@ (cd ../../fml; make check 2>&1 ) | grep -v OK || echo ''

link: clean_link _link

_link:
	ln -s ../../fml/doc/ja ja-doc
	ln -s ../../fml/doc/en en-doc
	ln -s ../../fml/etc
	ln -s ../../fml/lib
	ln -s ../../fml/lib/FML
	ln -s ../../fml/lib/FML/Filter
	ln -s ../../fml/lib/FML/Ticket
	ln -s ../../fml/lib/FML/CGI
	ln -s ../../fml/lib/FML/Process
	ln -s ../../fml/lib/FML/Command       Command
	ln -s ../../fml/lib/FML/Command/Admin AdminCommand
	ln -s ../../fml/lib/FML/Command/User  UserCommand
	ln -s ../../fml/lib/IO
	ln -s ../../fml/lib/File
	ln -s ../../fml/lib/Tie
	ln -s ../../fml/lib/Mail
	ln -s ../../fml/lib/Mail/HTML
	ln -s ../../fml/libexec
	ln -s /var/spool/ml/elena/log
	ln -s ../../cpan/doc doc-devel
	ln -s ../../fml/doc/ja/tutorial tutorial
	ln -s ../../fml/share/message/euc-jp  message-euc-jp
	ln -s ../../fml/share/template/euc-jp template-euc-jp

diff:
	@ (cd ../..;cvs diff -ub)


test:
	@ echo "* IO::* class test"
	@ apply perl IO/t/*pl
	@ test -d /tmp/fml5 || mkdir /tmp/fml5
	@ make -f ../base/Makefile
	@ (cd ../cf; make test)
	@ echo "* errormails"
	@ (cd ../errormails; make check)

regen:
	(cd ../../fml/etc; make )

diag:
	env PATH=/usr/pkg/bin:$$PATH make check
