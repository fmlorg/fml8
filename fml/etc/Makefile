#
# $FML: Makefile,v 1.13 2003/07/26 14:23:04 fukachan Exp $
#

OBJ		=	default_config.cf.ja \
			default_config.cf.en

TARGET_DIR	=	../../Documentation/ja/etc

CONV		=	$(PERL) ../../fml/utils/bin/text2html.pl


all: $(OBJ)

default_config.cf.ja.in: src/config.cf.ja/*.cf
	sh .gen.sh

default_config.cf.en.in: src/config.cf.en/*.cf
	sh .gen.sh

clean:
	rm -f $(OBJ)
	rm -f main.cf
