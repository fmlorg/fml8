#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: __template.pm,v 1.5 2001/04/03 09:45:39 fukachan Exp $
#

use strict;
use Carp;

my $base_addr = '10.20.30.';
my $i         = 1;

while (<>) {
    my $addr = $base_addr . $i++;
    s/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$addr/e;
    print;
}

exit 0;
