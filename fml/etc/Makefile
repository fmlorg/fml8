CONV =	perl ../../doc/bin/text2html.pl 

all: default_config.cf.ja html

default_config.cf.ja: defaults/*
	sh .gen.sh

html: defaults/variablelist.ja.html

defaults/variablelist.ja.html: defaults/*cf* defaults/Configurations
	$(CONV) default_config.cf.ja > defaults/variablelist.ja.html
