#
# $FML: Makefile,v 1.60 2003/01/03 10:17:28 fukachan Exp $
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
	- mv -f 33_TODO 33_TODO.bak
	- (cd ../../fml; make check 2>&1 |tee 33_TODO) | grep -v OK || echo ''
	@ echo "" >> 33_TODO
	- ./.gen_todo.pl \
	  `find lib/ -type f -print |\
	   egrep '\.pm$$' ` |\
	   sed -e 's@^lib//@@' -e 's@^lib/@@' |\
	   tee -a 33_TODO
	- mv -f 44_STYLE 44_STYLE.bak
	- ./find_bad_style.pl \
	  `find lib/ -type f -print |\
	   egrep '\.pm$$' ` |\
	   sed -e 's@^lib//@@' -e 's@^lib/@@' |\
	   tee 44_STYLE

link: clean_link _link

_link:
	ln -s ../../fml/doc/ja ja-doc
	ln -s ../../fml/doc/en en-doc
	ln -s ../../fml/etc
	ln -s ../../fml/lib
	ln -s ../../fml/lib/FML
	ln -s ../../fml/lib/FML/Filter
	ln -s ../../fml/lib/FML/CGI
	ln -s ../../fml/lib/FML/Process
	ln -s ../../fml/lib/FML/Command       Command
	ln -s ../../fml/lib/FML/Command/Admin AdminCommand
	ln -s ../../fml/lib/FML/Command/User  UserCommand
	ln -s ../../fml/lib/FML/MTAControl    MTAControl
	ln -s ../../fml/lib/IO
	ln -s ../../fml/lib/File
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


#
# re-generate files for fml/etc/ and fml/doc/
#

LIST_TARGET = ../../fml/doc/share/config/list_makefml_command.txt

regen: regen_default_config_cf regen_command_list

regen_default_config_cf:
	(cd ../../fml/etc; make )

regen_command_list: $(LIST_TARGET)

$(LIST_TARGET): ../../fml/etc/src/config.cf.ja/command.cf
	sh ../../fml/utils/bin/listup_commnads.sh
