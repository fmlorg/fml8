#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: search.pl,v 1.2 2001/05/04 14:32:35 fukachan Exp $
#

use IO::Adapter;
my $debug = defined $ENV{'debug'} ? 1 : 0;
my $map   = shift || 'file:/var/spool/ml/elena/actives';
my $obj   = new IO::Adapter $map;

$obj->open || croak("cannot open $map");
while ($x = $obj->getline) { print "<< ", $x if $x =~ /\S+/;}
print "\n";
$obj->close;

for ('rudo', 'fukachan') {
    print "* search $_ in $map\n";
    print $obj->find($_), "\n";
}

exit 0;
