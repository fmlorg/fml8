#
# $FML$
#

TARGET_DIR = ../../Documentation/ja/etc

CONV       = $(PERL) ../../doc/bin/text2html.pl 

all: default_config.cf.ja html

default_config.cf.ja: defaults/*
	sh .gen.sh

html: $(TARGET_DIR)/variablelist.html

$(TARGET_DIR)/variablelist.html: defaults/*cf* defaults/Configurations
	test -d $(TARGET_DIR) || mkdir $(TARGET_DIR)
	$(CONV) default_config.cf.ja > $(TARGET_DIR)/variablelist.html

