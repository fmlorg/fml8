#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: basic_io.pl,v 1.5 2002/04/18 14:18:09 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

my $test_mode = $ENV{'test_mode'} ? 1 : 0;

my $tmp = "/tmp/buf$$";

for my $f (@ARGV) {
    my $fh  = new FileHandle $f;
    my $wh  = new FileHandle "> $tmp";
    my $obj = Mail::Message->parse( { fd => $fh } );

    $wh->autoflush(1);
    $obj->print($wh);
    $wh->close;

    unless ($test_mode) {
	print "\n<< $f\n";
	my $h = $obj->data_type_list;
	for (@$h) { print "  ", $_, "\n";}
	print "\n";
    }

    use IO::Handle;
    my $fd = new IO::Handle;
    my $i  = 0;
    open($fd, "diff -ub $f $tmp|");
    while (<$fd>) { $i++; print "      ", $_ if $i > 3;}
    close($fd);

    print "$f ";
    print $i ? "fail" : "ok";
    print "\n";
}

unlink $tmp;

exit 0;
