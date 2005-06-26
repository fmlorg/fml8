#
# $FML: Makefile,v 1.1 2003/07/24 15:37:34 fukachan Exp $
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
