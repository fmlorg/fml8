#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

use strict;
use Carp;

my $debug = 0;
my $file  = "/etc/passwd";
my $map   = "file:". $file;

print STDERR "roll back test\n" if $debug;

use IO::MapAdapter;
my $obj = new IO::MapAdapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $pobot = 0;
my $done  = 0;
my $i     = 0;
my $pebot = 0;
my ($x, $prev_buf, $buf);

while ($x = $obj->getline) {
    $i++;
    if ($i == 4 || $i == 7) {
	print STDERR "      > ", $x if $debug;
	unless ($prev_buf) {
	    $prev_buf = $x;
	}
	$buf = $x;
    }

    if ($i == 3) {
	$pebot = $obj->getpos;
	print STDERR "     * roll back here\n" if $debug;
    }

    my $pos = $obj->getpos;
    unless ($done) {
	if ($i == 6) {
	    print STDERR "   now> ", $x if $debug;;
	    print STDERR "     * try to roll back ... \n" if $debug;;
	    $obj->setpos( $pebot );
	    $done = 1;
	} 
    }
}
$obj->close;


if ($prev_buf eq $buf) {
    print STDERR "$map roll back test ... ok\n";
    exit 0;
}
else {
    exit 1;
}

exit 0;
