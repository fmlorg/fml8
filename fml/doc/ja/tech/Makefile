#
# $FML: Makefile,v 1.1 2001/04/28 08:16:08 fukachan Exp $
#

###
### CONFIGURATIONS
###

SOURCE      = book
BOOK        = tech
BOOK_ID     = tips
TARGET_DIR  = ../../../../Documentation/ja/$(BOOK)


###
### RULES
###

_ARGV = SOURCE=$(SOURCE) BOOK=$(BOOK) BOOK_ID=$(BOOK_ID)
_MAKE = $(MAKE) -f ../Makefile.template $(_ARGV)


all: export

html:
	@ $(_MAKE) html

clean:
	@ $(_MAKE) clean

export:
	@ $(_MAKE) export

scan:
	@ $(_MAKE) scan
