#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: unixgroup_map.pl,v 1.4 2001/05/04 14:32:34 fukachan Exp $
#

use Carp;
use strict;

my $map = 'unix.group:wheel';

my @group  = getgrnam( 'wheel' );
my @member = split(/\s+/,$group[3]);

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}

my $x;
my @x = ();
while ($x = $obj->get_recipient) { push(@x, $x);}
$obj->close;

my $bad = 0;
my $id  = $$.time;
my $x   = join("-${id}-", sort @x);
my $m   = join("-${id}-", sort @member);

if ($x eq $m) {
    print "unix.group ... ok\n";
    exit 0;
}
else {
    print "unix.group ... fail\n";
    exit 1;
}

exit 0;
