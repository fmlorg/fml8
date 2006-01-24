#-*- perl -*-
#
#  Copyright (C) 2001,2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: file_map_getpos.pl,v 1.7 2002/04/01 23:41:15 fukachan Exp $
#

use strict;
use Carp;

my $debug = 0;
my $file  = "/etc/passwd";
my $map   = "file:$file";

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file roll back");

my $done  = 0;
my $i     = 0;
my $pebot = 0;
my ($x, $prev_buf, $buf);

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open || $tool->error("cannot open $map");
if ($obj->error) { $tool->error( $obj->error );}

LINE:
    while ($x = $obj->getline) {
	$i++;
	if ($i == 4 || $i == 7) {
	    print STDERR "      > ", $x if $debug;
	    unless ($prev_buf) {
		$prev_buf = $x;
	    }
	    $buf = $x;
	}

	if ($i == 3) {
	    $pebot = $obj->getpos;
	    print STDERR "     * roll back here\n" if $debug;
	}

	my $pos = $obj->getpos;
	unless ($done) {
	    if ($i == 6) {
		print STDERR "   now> ", $x if $debug;;
		print STDERR "     * try to roll back ... \n" if $debug;;
		$obj->setpos( $pebot );
		$done = 1;
	    }
	}
    }

$obj->close;
if ($obj->error) { $tool->error( $obj->error );}

$tool->diff($prev_buf, $buf);

exit 0;
