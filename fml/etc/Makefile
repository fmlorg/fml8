#
# $FML: Makefile,v 1.8 2001/11/27 09:30:40 fukachan Exp $
#

OBJ		=	main.cf	default_config.cf.ja

TARGET_DIR	=	../../Documentation/ja/etc

CONV		=	$(PERL) ../../fml/utils/bin/text2html.pl 


all: default_config.cf.ja.in

default_config.cf.ja.in: defaults/*
	sh .gen.sh

clean:
	rm -f $(OBJ)
