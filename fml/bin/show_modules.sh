#!/bin/sh

for x in libexec/[a-z]* FML/*pm
do
	sed '/=head1/,/=cut/d' $x |less
done
