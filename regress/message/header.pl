#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

my $tmp = "/tmp/buf$$";

for my $f (@ARGV) {
    my $fh   = new FileHandle $f;
    my $wh   = new FileHandle "> $tmp";
    my $obj  = Mail::Message->parse( { fd => $fh } );
    my $hdr  = $obj->whole_message_header();
    my $from = $hdr->get('from');

    use Mail::Address;
    my (@addrlist) = Mail::Address->parse($from);

    for my $a (@addrlist) {
	my $address = $a->address();
	print "address: $address\n";

	my $comment = $a->comment();
	print "comment: $comment\n";

	my $phrase = $a->phrase();
	print "phrase: $phrase\n";
    }

    print "\n";
}

unlink $tmp;

exit 0;
