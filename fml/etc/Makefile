#
# $FML: Makefile,v 1.12 2002/04/01 23:41:09 fukachan Exp $
#

OBJ		=	main.cf	default_config.cf.ja

TARGET_DIR	=	../../Documentation/ja/etc

CONV		=	$(PERL) ../../fml/utils/bin/text2html.pl


all: default_config.cf.ja.in default_config.cf.en.in

default_config.cf.ja.in: src/config.cf.ja/*.cf
	sh .gen.sh

default_config.cf.en.in: src/config.cf.en/*.cf
	sh .gen.sh

clean:
	rm -f $(OBJ)
