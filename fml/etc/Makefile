#
# $FML: Makefile,v 1.9 2001/12/09 10:18:17 fukachan Exp $
#

OBJ		=	main.cf	default_config.cf.ja

TARGET_DIR	=	../../Documentation/ja/etc

CONV		=	$(PERL) ../../fml/utils/bin/text2html.pl 


all: default_config.cf.ja.in

default_config.cf.ja.in: src/*cf src/*/*cf*
	sh .gen.sh

clean:
	rm -f $(OBJ)
