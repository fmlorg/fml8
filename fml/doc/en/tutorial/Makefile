#
# $FML: Makefile,v 1.2 2005/06/26 00:06:53 fukachan Exp $
# $jaFML: Makefile,v 1.11 2001/05/01 09:15:21 fukachan Exp $
#

# targets
TARGET      = book
TARGET_DIR = ../../../../Documentation/en/tutorial
ID          = techtips.html

###
### CONFIGURATIONS
###

SOURCE      = book
BOOK        = tutorial
BOOK_ID     = index
TARGET_DIR  = ../../../../Documentation/en/$(BOOK)


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
	perl ../../../../regress/doc/check.pl

