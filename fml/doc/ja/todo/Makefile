#
# $FML: Makefile,v 1.1.1.1 2001/05/19 05:14:57 fukachan Exp $
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


all: export STATUS.html

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
