#
# $FML$
#

index.html: draft-*
	perl .gen_index.pl draft-*txt > index.html.new
	mv index.html.new index.html

update:
	sh .update.sh
