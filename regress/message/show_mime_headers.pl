#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: show_mime_headers.pl,v 1.1 2004/12/08 07:27:33 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

my $test_mode = $ENV{'test_mode'} ? 1 : 0;

my $tmp = "/tmp/buf$$";

for my $f (@ARGV) {
    my $fh   = new FileHandle $f;
    my $wh   = new FileHandle "> $tmp";
    my $obj  = Mail::Message->parse( { fd => $fh } );
    my $head = $obj->whole_message_header();
    my $i    = 0;

    print "1. \n";
    $i = 0;
    for (my $m = $obj->{ next }; $m->{ next }; $m = $m->{ next }) { 
	++$i;
	print "($i) {";
	print $m->{ header };
	print "}\n";
    }

    print "2. \n";
    $i = 0;
    my $list = $obj->message_chain_as_array_ref();
    for my $m (@$list) {
	++$i;
	print "($i) {";
	print $m->{ header };
	print "}\n";
    }

}

unlink $tmp;

exit 0;
