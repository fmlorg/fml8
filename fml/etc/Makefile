#
# $FML: Makefile,v 1.6 2001/04/30 10:21:44 fukachan Exp $
#

TARGET_DIR = ../../Documentation/ja/etc

CONV       = $(PERL) ../../fml/utils/bin/text2html.pl 

all: default_config.cf.ja html

default_config.cf.ja: defaults/*
	sh .gen.sh

html: $(TARGET_DIR)/variablelist.html

$(TARGET_DIR)/variablelist.html: defaults/*cf* defaults/Configurations
	test -d $(TARGET_DIR) || mkdir $(TARGET_DIR)
	$(CONV) default_config.cf.ja > $(TARGET_DIR)/variablelist.html

