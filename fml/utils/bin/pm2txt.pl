#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: pm2txt.pl,v 1.3 2002/04/01 23:41:23 fukachan Exp $
#

use strict;
use Carp;
use vars qw($debug %PMList %TxtList);
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
    _make_index(@_);
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

	# saved for
	$PMList{ $src }  = $src;
	$TxtList{ $src } = $dst;

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


sub _make_index
{
    my ($src_dir, $dst_dir) = @_;
    my ($up_dir);
    my (%list, %pmlink, %txtlink);

    $up_dir = $dst_dir;
    $up_dir =~ s/\w+/../g;

    for (keys %PMList) {
	my $x = $_;
	$x =~ s/$src_dir//;
	$x =~ s@^/@@;
	$list{ $_ }    = $x;
	$pmlink{ $x }  = "$up_dir/$src_dir/$x";
    }

    my $dir = $src_dir;
    $dir =~ s@^/@@;
    $dir =~ s@/$@@;
    $dir =~ s@/@-@g;
    my $index = "$dst_dir/${dir}-index.html";
    my $wh = new FileHandle "> $index";

    print "generate $index\n";

    my $level = 0;
    print $wh "<TABLE>\n";
    for (sort keys %list) {
	my $name = $_;
	my $txt  = $TxtList{ $_ };
	my $x    = $list{ $_ };

	$name =~ s@$src_dir@@;
	$name =~ s@^/@@;
	$name =~ s@.pm$@@;
	$name =~ s@/@::@g;

	$txt  =~ s@$dst_dir@@;
	$txt  =~ s@^/@@;

	print $wh "<TR>\n";
	print $wh "<TD>$name\n";
	print $wh "<TD><A HREF=\"", $pmlink{ $x }, "\">[source]</A>\n";
	print $wh "<TD><A HREF=\"", $txt, "\">[manual]</A>\n";
	print $wh "\n";
    }
    print $wh "</TABLE>\n";

    $wh->close;
}

1;
