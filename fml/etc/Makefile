#
# $FML: Makefile,v 1.16 2003/12/21 06:53:32 fukachan Exp $
#

OBJ		=	default_config.cf.ja.in \
			default_config.cf.en.in

CLEANUP_OBJ	=	default_config.cf.ja \
			default_config.cf.en \
			main.cf \
			install.cf

all: $(OBJ)

default_config.cf.ja.in: src/config.cf.ja/*.cf
	sh .gen.sh

default_config.cf.en.in: src/config.cf.en/*.cf
	sh .gen.sh

clean:
	rm -f $(CLEANUP_OBJ)
	rm -f main.cf

check:
	@ echo // check .ja definitions.
	@ cat src/config.cf.ja/*cf |\
		../../regress/variable/definition_check.pl
	@ echo // check .en definitions.
	@ cat src/config.cf.en/*cf |\
		../../regress/variable/definition_check.pl
