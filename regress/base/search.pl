#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: search.pl,v 1.1 2001/04/15 09:09:03 fukachan Exp $
#

use IO::Adapter;

my $map = shift || 'file:/var/spool/ml/elena/actives';
my $obj = new IO::Adapter $map;

$obj->open || croak("cannot open $map");
while ($x = $obj->getline) { print "<< ", $x if $x =~ /\S+/;}
print "\n";
$obj->close;

for ('rudo', 'fukachan') {
    print "* search $_ in $map\n";
    print $obj->find($_), "\n";
}

exit 0;
