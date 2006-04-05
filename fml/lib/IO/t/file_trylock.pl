#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: file_lock.pl,v 1.1 2006/01/24 10:45:10 fukachan Exp $
#

use strict;
use Carp;

my $debug = 0;
my $i     = 0;
my $file  = "/tmp/io.adapter.$$";
my $map   = "file:$file";
my %log   = ();
my %pid   = ();

### MAIN ###
use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file lock/unlock");

use IO::Adapter;

for my $i (0 .. 5) {
    my $obj = new IO::Adapter $map;

    my $pid = fork();
    $pid{ $pid } = 1;
    if ($pid == 0) {
	my $t;
	my $ok;

	if ($obj->lock( { wait => 3 } )) {
	    $t = time;
	    $log{ $i } .= "locked\t";
	    $ok++;
	}
	else {
	    $t = time;
	    $log{ $i } .= "timeout\t";
	    $ok++;
	    if ($obj->lock()) {
		$log{ $i } .= "locked\t";
		$ok++;
	    }
	}

	sleep(rand(5));
	if ($obj->unlock()) {
	    $t = time - $t;
	    $log{ $i } .= "$t\tunlocked\n";
	    $ok++;
	}

	print STDERR "$i [$$]\t$log{ $i }" if $debug;
	if ($ok == 3) {
	    $tool->print_ok("[$$] (wait for $t sec, timeout-ed)");
	}
	elsif ($ok == 2) {
	    $tool->print_ok("[$$] (wait for $t sec)");
	}
	else {
	    $tool->print_error("[$$] (wait for $t sec)");
	}

	exit(0);
    }
}

# Wait for the child to terminate.
{
    my $dying;

  WAIT:
    while (($dying = wait()) != -1) {
	$pid{ $dying } = 0;

	my $found = 0;
	for my $i (keys %pid) {
	    $found++ if $pid{ $i };
	}

	last WAIT if $found;
    }
}

sleep 20;

exit 0;
