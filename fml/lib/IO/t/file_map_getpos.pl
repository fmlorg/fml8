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

my $file = "/etc/passwd";
my $map  = "file:". $file;

use IO::MapAdapter;
my $obj = new IO::MapAdapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $pobot = 0;
my $done  = 0;
my $i     = 0;
my $pebot = 0;
my $x;
while ($x = $obj->getline) {
    $i++;
    print "$i  ", $x;

    if ($i == 3) {
	$pebot = $obj->getpos;
	print STDERR "*** roll back here\n";
    }

    my $pos = $obj->getpos;
    unless ($done) {
	if ($i == 6) {
	    print STDERR "*** try to roll back ... \n";
	    $obj->setpos( $pebot );
	    $done = 1;
	} 
    }
}
$obj->close;

exit 0;
