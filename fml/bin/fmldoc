#!/usr/local/bin/perl
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
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
