#
# $FML: Makefile,v 1.15 2003/12/21 06:51:19 fukachan Exp $
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
