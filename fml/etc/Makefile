#
# $FML: Makefile,v 1.7 2001/04/30 13:34:16 fukachan Exp $
#

TARGET_DIR = ../../Documentation/ja/etc

CONV       = $(PERL) ../../fml/utils/bin/text2html.pl 

all: default_config.cf.ja.in

default_config.cf.ja.in: defaults/*
	sh .gen.sh
