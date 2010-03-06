#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: scramble.pl,v 1.4 2006/11/24 06:51:15 fukachan Exp $
#

use strict;
use Carp;

my $mode        = $ENV{ MODE }          || "post";
my $from        = $ENV{ FML_EMUL_FROM } || undef;
my $from_found  = 0;
my $date_found  = 0;
my $msgid_found = 0;

# unix from
print "From $from\n";

# main part
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

if ($mode eq "post") {
    # avoid body loop check.
    require 'ctime.pl';
    print "\n";
    print "XXX AVOID BODY CHECKSUM LOOP CHECK: ";
    print ctime(time);
    print "\n";
}

exit 0;
