#
# $FML$
#

PERL = perl

index.html: rfc*txt
	$(PERL) .track_relation.pl > index.html.new
	mv index.html.new index.html
