#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: .conv_classname.pl,v 1.1 2001/04/04 03:27:12 fukachan Exp $
#

use strict;
use Carp;

my $class  = '';
my $name   = '';
my %module = ();

while (<>) {
    if (/^(\S+)\:\:/) {
	$class = $1;
	next;
    }

    if (/^\:\:/) {
	my ($name, $status, @x) = split(/\s+/, $_);
	undef $x[ $#x ];
	my $module = sprintf("%-30s", $class . $name);
	my $desc   = join(" ", @x);

	print $module, $desc, "\n";
	if (0) { $module{ $module } = $desc; };
    }    
}

if (0) {
    for my $module (sort keys %module) {
	print $module, $module{ $module }, "\n";
    }
}

exit 0;
