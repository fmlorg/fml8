#
# $FML: Makefile,v 1.2 2001/04/28 10:01:47 fukachan Exp $
#

###
### CONFIGURATIONS
###

SOURCE      = book
BOOK        = tech
BOOK_ID     = tips
TARGET_DIR  = ../../../../Documentation/ja/$(BOOK)

# local
LOCAL_SOURCE = os_and_perl.sgml


###
### RULES
###

_ARGV = SOURCE=$(SOURCE) BOOK=$(BOOK) BOOK_ID=$(BOOK_ID)
_MAKE = $(MAKE) -f ../Makefile.template $(_ARGV)


all: $(LOCAL_SOURCE) export

html:
	@ $(_MAKE) html

clean:
	@ $(_MAKE) clean

export:
	@ $(_MAKE) export

scan:
	@ $(_MAKE) scan


#
# local
#

os_and_perl.sgml: OS_and_Perl.data
	perl ../utils/bin/data2sgml.pl OS_and_Perl.data > os_and_perl.sgml
