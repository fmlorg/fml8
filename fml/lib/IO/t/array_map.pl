#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: array_map.pl,v 1.5 2002/01/27 13:11:59 fukachan Exp $
#

use Carp;
use strict;

my $map = ['a', 'b', 'c'];

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $x;
my @recipients = ();
while ($x = $obj->get_next_key) { push(@recipients, $x); }
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
