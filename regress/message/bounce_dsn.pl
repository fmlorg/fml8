#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: basic_io.pl,v 1.2 2001/04/08 05:05:10 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

for my $f (@ARGV) {
    my $fh  = new FileHandle $f;
    my $msg = Mail::Message->parse( { fd => $fh } );

    use Mail::Bounce::DSN;
    my $r = Mail::Bounce::DSN->analyze( $msg );
    # use Data::Dumper; print Dumper( $r );
}

exit 0;
