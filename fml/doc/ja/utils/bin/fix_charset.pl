#!/usr/local/bin/perl
#
# $FML: .fix_charset.pl,v 1.1 2001/04/23 17:15:52 fukachan Exp $
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
