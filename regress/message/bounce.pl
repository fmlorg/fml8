#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: bounce.pl,v 1.8 2001/07/30 23:00:06 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib);
use Mail::Message;

for my $f (@ARGV) {
    print "// check $f\n" if $ENV{'debug'};
    my $fh  = new FileHandle $f;
    my $msg = Mail::Message->parse( { fd => $fh } );
    my $r   = {};

    use Mail::Bounce;
    my $bouncer = new Mail::Bounce;
    $bouncer->analyze( $msg );
    print "\n--- result (debug)\n\n" if $ENV{'debug'};
    printf "# %-20s ... %s\n", $f, ($bouncer->address_list ? "ok" : "fail");

    if ($ENV{'dump'}) { 
	eval qq{ require Data::Dumper; Data::Dumper->import();};
	print $@ if $@;
	eval q{ print Dumper( $msg ); };
    }

    for my $a ( $bouncer->address_list ) {
	print "address: $a\n";

	print " status: ";
	print $bouncer->status( $a );
	print "\n";

	print " reason: ";
	print $bouncer->reason( $a );
	print "\n";

	print "  hints: ";
	print $bouncer->hints( $a );
	print "\n";

	print "\n";
    }
}

exit 0;
