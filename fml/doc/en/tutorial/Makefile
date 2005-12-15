#
# $FML: Makefile,v 1.4 2005/10/29 05:14:11 fukachan Exp $
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

_ARGV = SOURCE=$(SOURCE) BOOK=$(BOOK) BOOK_ID=$(BOOK_ID) LANG_HINT=en
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

recipe:
	@ perl ../../../../regress/doc/cat.pl |\
		perl ../../../../regress/doc/listup_recipe.pl
