#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: scramble.pl,v 1.2 2002/12/30 13:18:50 fukachan Exp $
#

use strict;
use Carp;

my $from        = undef;
my $from_found  = 0;
my $date_found  = 0;
my $msgid_found = 0;

if (defined $ENV{ FML_EMUL_FROM }) {
    $from = $ENV{ FML_EMUL_FROM };
} 

while (<>) {
    if (/^date:/i) {
		$date_found = 1;
	}

    if (/^message-id/i) {
	my $time = time;
	s/\d+/$time.$$/g;
	$msgid_found = 1;
    }

    if (defined($from) && /^From:/ && (not $from_found)) {
	s/\S+\@\S+/$from/;
	$from_found = 1;
    }

    if (/^$/) {
	unless ($msgid_found) {
		my $time = time;
		my $host = `hostname`; chomp $host;
		print "Message-ID: <$time\@$host>\n";
		$msgid_found = 1;
	}

	unless ($date_found) {
		print "Date: ";
		print `date +"%a, %d %b %Y %H:%M:%S +0900 (JST)."`;
		$date_found = 1;
	}
    }

    print $_;
}

exit 0;
