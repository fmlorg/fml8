#
# $FML: Makefile,v 1.11 2002/02/18 12:29:43 fukachan Exp $
#

OBJ		=	main.cf	default_config.cf.ja

TARGET_DIR	=	../../Documentation/ja/etc

CONV		=	$(PERL) ../../fml/utils/bin/text2html.pl


all: default_config.cf.ja.in

default_config.cf.ja.in: src/config.cf.ja/*.cf
	sh .gen.sh

clean:
	rm -f $(OBJ)
