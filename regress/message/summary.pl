#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: summary.pl,v 1.1 2004/03/28 13:15:07 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

my $test_mode = $ENV{'test_mode'} ? 1 : 0;

my $tmp = "/tmp/buf$$";

for my $f (@ARGV) {
    print "// $f\n";	

    my $fh  = new FileHandle $f;
    my $wh  = new FileHandle "> $tmp";
    my $msg = Mail::Message->parse( { fd => $fh } );

    print $msg->one_line_summary();
    print "\n";
    print "\n";
}

unlink $tmp;

exit 0;
