#!/bin/sh

for x in libexec/fml.pl FML/*pm
do
	sed '/=head1/,/=cut/d' $x |less
done
