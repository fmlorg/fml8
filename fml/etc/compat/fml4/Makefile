#
# $FML: Makefile,v 1.1.1.1 2004/11/25 12:29:22 fukachan Exp $
#

PERL      = perl

BASE_DIR  = ../../../../gnu/dist/fml4/cf

TMP       = ./tmp.new

TEMPLATE  = cf.recommended

CONFIGURE = $(PERL) $(BASE_DIR)/config 

default_config.ph: $(BASE_DIR)/config $(BASE_DIR)/MANIFEST $(TEMPLATE)
	$(CONFIGURE) -m $(BASE_DIR)/MANIFEST -i $(TEMPLATE) > $(TMP)
	mv $(TMP) default_config.ph
