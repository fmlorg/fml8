#
# $FML$
#

PERL      = perl

BASE_DIR  = ../../../../gnu/dist/fml4/cf

TMP       = ./tmp.new

TEMPLATE  = cf.recommended

CONFIGURE = $(PERL) $(BASE_DIR)/config 

default_config.ph: $(BASE_DIR)/config $(BASE_DIR)/MANIFEST $(TEMPLATE)
	$(CONFIGURE) -m $(BASE_DIR)/MANIFEST $(TEMPLATE) > $(TMP)
	mv $(TMP) default_config.ph
