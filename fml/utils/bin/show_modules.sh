#!/bin/sh
#
# $Id$
#

for x in libexec/[a-z]* FML/*pm
do
	sed '/=head1/,/=cut/d' $x |less
done

exit 0
