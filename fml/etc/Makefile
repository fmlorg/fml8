#
# $FML: Makefile,v 1.14 2003/12/21 06:50:07 fukachan Exp $
#

OBJ		=	default_config.cf.ja \
			default_config.cf.en

all: $(OBJ)

default_config.cf.ja.in: src/config.cf.ja/*.cf
	sh .gen.sh

default_config.cf.en.in: src/config.cf.en/*.cf
	sh .gen.sh

clean:
	rm -f $(OBJ)
	rm -f main.cf
