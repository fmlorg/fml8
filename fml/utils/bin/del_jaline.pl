#!/usr/bin/env perl
#-*- perl -*-
#
# Copyright (C) 2000,2003 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
#

my $re_euc_c  = '[\241-\376][\241-\376]';

while (<>) {
    next if /$re_euc_c/;
    print;
}

exit 0;
