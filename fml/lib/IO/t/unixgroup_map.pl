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

my $map = 'unix.group:wheel';

use IO::MapAdapter;
my $obj = new IO::MapAdapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $x;
my @recipients = ();
while ($x = $obj->get_recipient) { print $x, "\n";}
$obj->close;


exit 0;
