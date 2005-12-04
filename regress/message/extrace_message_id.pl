#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: extrace_message_id.pl,v 1.2 2005/07/27 12:16:20 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib lib);
use Mail::Message;

my $test_mode = $ENV{'test_mode'} ? 1 : 0;

for my $f (@ARGV) {
    print "\n\n\n";
    print "=" x 60;
    print "\n// $f \n\n";

    my $fd  = new FileHandle $f;
    my $msg = Mail::Message->parse( {
        fd           => $fd,
        header_class => 'FML::Header',
    });

    my $header = $msg->whole_message_header;
    my $mid    = $header->get('message-id');

    print "Message-ID: ";
    print $header->get('message-id');
    print "\n";
    print "\n";
    print "  cleanup> ", $header->address_cleanup($mid);
    print "\n";
    print "\n";
    print "In-Reply-To: ";
    print $header->get('in-reply-to');
    print "\n";
    print "References: ";
    print $header->get('references');
    print "\n   ";
    print "-" x 50;
    print "\n";

    $mid = $header->extract_message_id_references();
    if (@$mid) {
	for (@$mid) {
	    print "message-id:\t", $_, "\n";
	}
    }
}

exit 0;
