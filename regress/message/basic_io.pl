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

    # use Data::Dumper; print Dumper( $obj );

    my $h = $obj->get_data_type_list;
    for (@$h) { print "  ", $_, "\n";}

    print "\n";
    use IO::Handle;
    my $fd = new IO::Handle;
    my $i  = 0;
    open($fd, "diff -ub $f $tmp|");
    while (<$fd>) { $i++; print "      ", $_ if $i > 3;}
    close($fd);
}

unlink $tmp;

exit 0;
