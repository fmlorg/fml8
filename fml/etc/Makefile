CONV =	perl ../../doc/bin/text2html.pl 

all: default_config.cf.ja html

default_config.cf.ja: defaults/*
	sh .gen.sh

html:
	$(CONV) defaults/NAMING_CONVENTION.txt > defaults/naming_conventin.ja.html
	$(CONV) default_config.cf.ja > defaults/variablelist.ja.html
