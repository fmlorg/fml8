#
# $FML: Makefile,v 1.10 2001/12/18 11:36:32 fukachan Exp $
#

OBJ		=	main.cf	default_config.cf.ja

TARGET_DIR	=	../../Documentation/ja/etc

CONV		=	$(PERL) ../../fml/utils/bin/text2html.pl 


all: default_config.cf.ja.in

default_config.cf.ja.in: src/config.cf.ja/*.cf
	sh .gen.sh

clean:
	rm -f $(OBJ)
