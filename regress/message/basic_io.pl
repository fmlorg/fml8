#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: __template.pm,v 1.5 2001/04/03 09:45:39 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

for my $f (@ARGV) {
    my $tmp = "/tmp/buf$$";
    my $fh  = new FileHandle $f;
    my $wh  = new FileHandle "> $tmp";
    my $obj = Mail::Message->parse( $fh );

    $wh->autoflush(1);
    $obj->print($wh);

    print "-- $f ";
    system "diff -ub $f $tmp";
    print $@ ? "fail\n": "ok\n";
}

exit 0;
