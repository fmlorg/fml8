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

    for (my $m = $obj ; $m->{ next }; $m = $m->{ next }) { 
	print $m->{ header };
	print "\n";
    }

}

unlink $tmp;

exit 0;
