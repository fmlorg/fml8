#
# $FML: Makefile,v 1.13 2005/06/25 13:16:30 fukachan Exp $
#

# targets
TARGET      = book
TARGET_DIR = ../../../../Documentation/ja/tutorial
ID          = techtips.html

###
### CONFIGURATIONS
###

SOURCE      = book
BOOK        = tutorial
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

text:
	@ $(_MAKE) w3m

clean:
	@ $(_MAKE) clean

export:
	@ $(_MAKE) export

scan:
	@ $(_MAKE) scan

check:
	@ perl ../../../../regress/doc/check.pl

