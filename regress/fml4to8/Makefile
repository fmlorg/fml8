#
# $FML$
#

PERL     = perl
CONV     = ../../gnu/dist/fml4/cf/config
MANIFEST = ../../gnu/dist/fml4/cf/MANIFEST

all: default_config.ph

default_config.ph: $(CONV) $(MANIFEST)
	$(PERL) $(CONV) -m $(MANIFEST) -i > default_config.ph.new
	mv default_config.ph.new default_config.ph

