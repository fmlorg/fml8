#
# $FML: Makefile,v 1.1 2001/05/19 06:03:02 fukachan Exp $
#

# targets
TARGET      = book
TARGET_DIR = ../../../../Documentation/ja/tutorial
ID          = techtips.html

###
### CONFIGURATIONS
###

SOURCE      = book
BOOK        = recipies
BOOK_ID     = index
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
