#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: basic_io.pl,v 1.1.1.1 2001/04/07 12:47:01 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

my $tmp = "/tmp/buf$$";

for my $f (@ARGV) {
    my $fh  = new FileHandle $f;
    my $wh  = new FileHandle "> $tmp";
    my $obj = Mail::Message->parse( { fd => $fh } );

    $wh->autoflush(1);
    $obj->print($wh);

    print "\n<< $f\n";

    my $newobj = $obj->dup_header;

    for my $k (sort keys %$obj ) {
	if ( $obj->{ $k } ne $newobj->{ $k } ) {
	    printf "%-15s is different.\n", $k;
	    print "     $obj->{ $k } != $newobj->{ $k }\n";
	}
	else {
	    printf "%-15s is same.\n", $k;
	}
    }
}

unlink $tmp;

exit 0;
