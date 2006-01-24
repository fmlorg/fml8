#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: array_map.pl,v 1.6 2002/04/01 23:41:14 fukachan Exp $
#

use Carp;
use strict;

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("array read");

my $map = ['a', 'b', 'c'];

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open || $tool->error("cannot open $map");
if ($obj->error) { $tool->error( $obj->error );}

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
    $tool->print_ok();
}
else {
    $tool->error();
}

exit 0;
