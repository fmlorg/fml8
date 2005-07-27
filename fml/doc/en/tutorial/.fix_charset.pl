#!/usr/bin/env perl
#
# $FML: .fix_charset.pl,v 1.1 2003/07/24 15:37:34 fukachan Exp $
# $jaFML: .fix_charset.pl,v 1.1 2001/04/23 17:15:52 fukachan Exp $
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
