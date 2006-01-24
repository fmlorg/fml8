#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: unixgroup_map.pl,v 1.7 2002/04/01 23:41:15 fukachan Exp $
#

use Carp;
use strict;
use FML::Test::Utils;

my $map = 'unix.group:wheel';

my $tool = new FML::Test::Utils;
$tool->set_title("group read ($map)");

my @group  = getgrnam( 'wheel' );
my @member = split(/\s+/,$group[3]);

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $x;
my @x = ();
while ($x = $obj->get_next_key) { push(@x, $x);}
$obj->close;

my $bad = 0;
my $id  = $$.time;
my $x   = join("-${id}-", sort @x);
my $m   = join("-${id}-", sort @member);

$tool->diff($x, $m);

exit 0;
