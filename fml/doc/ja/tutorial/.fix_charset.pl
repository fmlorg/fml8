#!/usr/local/bin/perl
#
# $FML$
#

use strict;

my $meta = q#
<META http-equiv="Content-Type"
        content="text/html; charset=EUC-JP">
#;

while (<>) {
	s/<META/${meta}$&/;
	print;
}

exit 0;
