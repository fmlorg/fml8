#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#

use strict;
use Carp;
use vars qw($debug);
use FileHandle;
use File::stat;

convert(@ARGV);

exit 0;


sub convert
{
    my ($src_dir, $dst_dir) = @_;

    print STDERR "convert $src_dir/ => $dst_dir/\n\n";

    _mkdir(@_);
    _convert(@_);
}


sub _mkdir
{
    my ($src_dir, $dst_dir) = @_;

    print STDERR "\nchecking directory under $dst_dir\n" if $debug;
    my $fh = new FileHandle;
    open($fh, "find $src_dir -type d -print|");
    while (<$fh>) {
	next if /CVS/;

	chop;
	s/$src_dir//;
	s@^/@@;

	my $dir = "$dst_dir/$_";
	unless (-d $dir) {
	    print STDERR "   mkdir $dir\n";
	    mkdir($dir, 0755);
	}
    }
    close($fh);
}


sub _convert
{
    my ($src_dir, $dst_dir) = @_;
    my ($src, $dst);
    my ($sstat, $dstat, $go);

    my $fh = new FileHandle;
    open($fh, "find $src_dir -type f -print|");
    while (<$fh>) {
	next if /__template.pm/;
	next unless /\.pm$/;
	chop;

	$dst = $src = $_;
	$dst =~ s/$src_dir/$dst_dir/;
	$dst =~ s@^/@@;
	$dst =~ s@//@/@g;
	$dst =~ s/.pm/.txt/;

	$go = 0;
	$sstat = stat($src) || croak("cannot stat $src");

	if (-f $dst) {
	    $dstat = stat($dst) || croak("cannot stat $dst");
	    $go = 1 if ( $sstat->mtime > $dstat->mtime );
	}
	else {
	    $go = 1;
	}

	if ( $go ) {
	    print STDERR "   pod2text $src > $dst.new\n";
	    system "pod2text $src > $dst.new";
	    print STDERR "   rename $dst.new $dst\n";
	    unless (rename("$dst.new", $dst)) {
		print STDERR "\t*** conversion error ***\n";
	    }
	}
    }
    close($fh);
}


1;
