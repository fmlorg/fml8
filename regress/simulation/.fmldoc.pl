#!/usr/bin/env perl
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: .fmldoc.pl,v 1.2 2001/04/03 09:51:13 fukachan Exp $
#

=head1 NAME

fmldoc -- wrapper for pod2man

=head1 SYNOPSIS

fmldoc filename

=head1 DESCRIPTION

=cut

for $file (@ARGV) {
    $file =~ s@::@/@g;
    system "pod2man $file | nroff -man |less";
}

1;
