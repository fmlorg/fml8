#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: .fix_addr.pl,v 1.2 2001/04/10 14:34:54 fukachan Exp $
#

use strict;
use Carp;

my $base_addr = '10.20.30.';
my $i         = 1;

while (<>) {
    # domain 
    s/sapporo.iij.ad.jp/fml.org/g;
 
    # scramble ip address information  
    my $addr = $base_addr . $i++;
    s/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$addr/e;
    print;
}

exit 0;
