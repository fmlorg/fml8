#
# $FML: Makefile,v 1.2 2002/04/11 15:10:10 fukachan Exp $
#

# targets
TARGET      = book
TARGET_DIR = ../../../../Documentation/ja/tutorial
ID          = techtips.html

###
### CONFIGURATIONS
###

SOURCE      = book
BOOK        = todo
BOOK_ID     = index
TARGET_DIR  = ../../../../Documentation/ja/$(BOOK)


###
### RULES
###

_ARGV = SOURCE=$(SOURCE) BOOK=$(BOOK) BOOK_ID=$(BOOK_ID)
_MAKE = $(MAKE) -f ../Makefile.template $(_ARGV)


all: export STATUS.html MEMO.html

html:
	@ $(_MAKE) html

clean:
	@ $(_MAKE) clean

export:
	@ $(_MAKE) export

scan:
	@ $(_MAKE) scan

STATUS.html: STATUS.txt
	perl ../../../utils/bin/text2html.pl STATUS.txt > STATUS.html.new
	mv STATUS.html.new STATUS.html

MEMO.html:  ../../../../regress/simulation/00_MEMO
	(	echo "MEMO (from regress/simulation/00_MEMO)";\
		echo ""; \
		egrep '^\[TODO\]' ../../../../regress/simulation/00_MEMO;\
	) | nkf -e |\
	perl ../../../utils/bin/text2html.pl > MEMO.html.new
	mv MEMO.html.new MEMO.html
