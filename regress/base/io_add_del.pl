#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: search.pl,v 1.3 2002/04/18 14:18:08 fukachan Exp $
#

use strict;
use Carp;
use IO::Adapter;
my $debug = defined $ENV{'debug'} ? 1 : 0;
my $map   = shift || 'file:/var/spool/ml/elena/etc/passwd-admin';
my $obj   = new IO::Adapter $map;
my $key   = 'fukachan@sapporo.iij.ad.jp';

_dump(1);

$obj->open || croak("cannot open $map");

$obj->delete($key);
$obj->add($key, crypt($$, $$));

$obj->close;

_dump(2);

exit 0;


sub _dump
{
    my ($i) = @_;
    my $x;

    print "\n<<< $i >>>\n";

    $obj->open();
    while ($x = $obj->getline()) { 
	print "<< ", $x if $x =~ /\S+/;
    }

    my $a = $obj->get_value_as_array_ref( $key );
    if (defined $a) {
	print "'$key' => '", $a->[0], "'\n";
    }
    $obj->close();
}
