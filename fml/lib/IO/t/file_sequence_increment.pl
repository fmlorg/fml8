#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: sequence.pl,v 1.1 2004/04/11 12:58:40 fukachan Exp $
#

use strict;
use Carp;

my $debug = 0;
my $i     = 0;
my $file  = "/tmp/io.$$";
my $map   = "file:$file";
my %log   = ();
my %pid   = ();
my $fail  = 0;
my $reason = '';

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file sequence increment");

use IO::Adapter;

for my $i (0 .. 5) {
    my $obj = new IO::Adapter $map;
    my $id  = $obj->sequence_increment();

    unless ($id == ($i + 1)) {
	$reason .= "wrong sequence returned";
	$reason .= "\t\n";
	$fail++;
    }

    if ($obj->error()) {
	$reason .= $obj->error();
	$reason .= "\t\n";
	$fail++;
    }
}

if ($fail) {
    $tool->print_error($reason);
}
else {
    $tool->print_ok();
}

exit 0;
