#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

use Carp;
use strict;

my $map = ['a', 'b', 'c'];

use IO::MapAdapter;
my $obj = new IO::MapAdapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $x;
my @recipients = ();
while ($x = $obj->get_recipient) { push(@recipients, $x); }
$obj->close;

my $ok = 0;
my $i  = 0;
for my $c (@$map) {
    $c eq $recipients[ $i ] && $ok++;
    $i++;
}

if ($ok == $i) {
    print STDERR "$map reading ... ok\n";
}
else {
    exit 1;
}

exit 0;
