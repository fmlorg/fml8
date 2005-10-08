#
# $FML: Makefile,v 1.79 2004/05/22 13:37:32 fukachan Exp $
#

TMPFILE	=	/tmp/log.fml-devel.test

all: link

clean:
	@ (cd ../..; find fml regress |grep '~' |perl -nple unlink)

allclean: clean clean_link
	rm -f __scan__

clean_link:
	for file in * ; do  test -h $$file && rm -f $$file || true ; done

scan:
	@ (cd ../..; make scan 2>&1) |tee __scan__ || echo 'nothing changed'
	@ cp __scan__ /tmp/fmlsrc.__scan__

update:
	@ (cd ../..; make update)

check:
	- test -f 33_TODO && mv -f 33_TODO 33_TODO.bak
	@ echo "   *********** 00_MEMO ********** " >> 33_TODO
	- grep '^\[TODO' 00_MEMO >> 33_TODO
	@ echo "" >> 33_TODO
	@ echo "   *********** PERL SYNTAX CHECKS ********** " >> 33_TODO
	- (cd ../../fml; make check 2>&1 |\
		grep -v 'syntax OK' |\
		tee -a ../regress/simulation/33_TODO) |\
		grep -v OK || echo ''
	@ echo "" >> 33_TODO
	@ echo "   *********** CHECK VARIABLE DEFINITIONS ********** " >> 33_TODO
	@ ../variable/diff.pl >> 33_TODO
	@ echo "" >> 33_TODO
	@ echo "   *********** STATUS.txt ********** " >> 33_TODO
	@ echo "" >> 33_TODO
	- egrep '^[0-9]|\[TODO\]' ../../fml/doc/ja/todo/STATUS.txt >> 33_TODO
	@ echo "" >> 33_TODO
	@ echo "   *********** XXX-TODO ********** " >> 33_TODO
	@ echo "" >> 33_TODO
	- ./.gen_todo.pl \
	  `find lib/ -type f -print |\
	   egrep '\.pm$$' ` |\
	   sed -e 's@^lib//@@' -e 's@^lib/@@' |\
	   tee -a 33_TODO
	- test -f 44_STYLE && mv -f 44_STYLE 44_STYLE.bak
	- ../style/find_bad_style.pl \
	  `find lib/ -type f -print |\
	   egrep '\.pm$$' ` |\
	   sed -e 's@^lib//@@' -e 's@^lib/@@' |\
	   tee 44_STYLE
	@ echo "-- check messages"
	@ (cd ../../fml/share/message; sh .diag.sh ) >> 33_TODO
	@ echo "-- check tutorial"
	@ make _doc_check |tee -a 33_TODO
	@ echo "-- clean up."
	- test -s 33_TODO  || rm -f 33_TODO
	- test -s 44_STYLE || rm -f 44_STYLE
	@ echo ""; echo "-- summary"; echo "";
	@ echo -n "TODO: ";
	@ grep TODO 33_TODO| wc -l

link: clean_link _link

_link:
	ln -s ../../fml/doc/ja ja-doc
	ln -s ../../fml/doc/en en-doc
	ln -s ../../fml/etc
	ln -s ../../fml/lib
	ln -s ../../fml/lib/FML
	ln -s ../../fml/lib/FML/Filter
	ln -s ../../fml/lib/FML/CGI
	ln -s ../../fml/lib/FML/ML
	ln -s ../../fml/lib/FML/Merge/FML4 Merge
	ln -s ../../fml/lib/FML/Process
	ln -s ../../fml/lib/FML/Command       Command
	ln -s ../../fml/lib/FML/Command/Admin AdminCommand
	ln -s ../../fml/lib/FML/Command/User  UserCommand
	ln -s ../../fml/lib/FML/MTAControl    MTAControl
	ln -s ../../fml/lib/IO
	ln -s ../../fml/lib/Tie
	ln -s ../../fml/lib/Mail
	ln -s ../../fml/lib/Mail/ThreadTrack
	ln -s ../../fml/libexec
	ln -s /var/spool/ml/elena/log
	ln -s ../../cpan/doc doc-devel
	ln -s ../../fml/doc/ja/tutorial tutorial
	ln -s ../../fml/doc/ja/todo     TODO
	ln -s ../../fml/doc/ja/recipes  recipies
	ln -s ../../fml/share/message/euc-jp  message-euc-jp

diff:
	@ (cd ../..;cvs diff -ub)

test:
	@ make _test 2>&1 | tee $(TMPFILE)
	@ echo ""; echo "--- summary ---"; echo "";
	@ egrep '\* |fail *$$' $(TMPFILE) |\
		sed 's|text=empty fail|text=empty fail (ok)|' || echo ''
	@ rm -f $(TMPFILE)

_test:
	@ echo "* IO::* class test"
	@ apply perl IO/t/*pl
	@ test -d /tmp/fml5 || mkdir /tmp/fml5
	@ make -f ../base/Makefile
	@ (cd ../cf; make test)
	@ echo "* errormails"
	@ (cd ../errormails; make check)

diag:
	env PATH=/usr/pkg/bin:$$PATH make check

depend:
	perl ../style/list_up_dependence.pl `find lib/ -type f |grep pm` |\
	tee 55_DEPEND.bak


#
# re-generate files for fml/etc/ and fml/doc/
#

LIST_TARGET = ../../fml/doc/share/config/list_makefml_command.txt

regen: regen_default_config_cf regen_command_list _doc_tutorial

regen_default_config_cf:
	(cd ../../fml/etc; make )

regen_command_list: $(LIST_TARGET)

$(LIST_TARGET): ../../fml/etc/src/config.cf.ja/command.cf
	sh ../../fml/utils/bin/listup_commnads.sh

_doc_tutorial:
	(cd ../../fml/doc/ja/tutorial;make -f Makefile.local)
	(cd ../../fml/doc/en/tutorial;make -f Makefile.local)

_doc_check:
	(cd ../../fml/doc/ja/tutorial;make check)
	(cd ../../fml/doc/en/tutorial;make check)


