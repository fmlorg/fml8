#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: bounce.pl,v 1.1 2001/04/09 15:33:30 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

for my $f (@ARGV) {
    my $fh  = new FileHandle $f;
    my $msg = Mail::Message->parse( { fd => $fh } );
    my $r   = {};

    for my $pkg ('DSN', 'Postfix19991231', 'Qmail') {
	print "--- $pkg\n";
	eval qq { 
	    require Mail::Bounce::$pkg; 
	    \$r = Mail::Bounce::$pkg->analyze( \$msg );
	};
	print $@ if $@;

	eval q{ use Data::Dumper; print Dumper( $r );};
	print $@ if $@;
    }
}

exit 0;
