#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: scramble.pl,v 1.1 2001/04/14 14:35:08 fukachan Exp $
#

use strict;
use Carp;

my $from = undef;
my $from_found = 0;

if (defined $ENV{ FML_EMUL_FROM }) {
    $from = $ENV{ FML_EMUL_FROM };
} 

while (<>) {
    if (/message-id/i) {
	my $time = time;
	s/\d+/$time.$$/g;
    }

    if (defined($from) && /^From:/ && (not $from_found)) {
	s/\S+\@\S+/$from/;
	$from_found = 1;
    }

    print $_;
}

exit 0;
