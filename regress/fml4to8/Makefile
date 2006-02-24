#
# $FML: Makefile,v 1.1 2004/03/15 09:20:51 fukachan Exp $
#

PERL     = perl
CONV     = ../../gnu/dist/fml4/cf/config
MANIFEST = ../../gnu/dist/fml4/cf/MANIFEST

all: default_config.ph

default_config.ph: $(CONV) $(MANIFEST)
	$(PERL) $(CONV) -m $(MANIFEST) -i > default_config.ph.new
	mv default_config.ph.new default_config.ph


work/CF: conv_manifest.pl ../../gnu/dist/fml4/cf/MANIFEST
	perl conv_manifest.pl ../../gnu/dist/fml4/cf/MANIFEST > work/CF.new
	mv work/CF.new work/CF

test: work/CF
	@ echo "edit CF from work/CF. O.K ?"
	perl test.pl CF /var/tmp/fml4to8
	( cd ../../ ;\
	  env debug=1 perl regress/fml4to8/configtest.pl /var/tmp/fml4to8;\
	)

clean:
	( cd ../simulation/ ; make clean )
