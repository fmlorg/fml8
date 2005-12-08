#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: io_add_del.pl,v 1.1 2002/09/06 13:24:35 fukachan Exp $
#

use strict;
use Carp;
use IO::Adapter;
my $debug = defined $ENV{'debug'} ? 1 : 0;
my $map   = 'pcre:/var/spool/ml/elena/sender.pcre';
my $obj   = new IO::Adapter $map;

my $key = 'fukachan@sapporo.iij.ad.jp';
print "search $key\n";
$obj->open || croak("cannot open $map");
print ( $obj->find($key) || "not found");
$obj->close();
print "\n\n";

my $key = 'fukachan@fml.org';
print "search $key\n";
$obj->open || croak("cannot open $map");
print ( $obj->find($key) || "not found");
$obj->close();
print "\n\n";

exit 0;
