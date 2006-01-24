#!/usr/bin/env perl
#
#  Copyright (C) 2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: lock.pl,v 1.7 2002/05/11 08:34:52 fukachan Exp $
#

use strict;
my $debug = defined $ENV{'debug'} ? 1 : 0;

my $map = "/tmp/fml8";

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file lock");

use IO::Adapter;
my $io = new IO::Adapter $map;
my $r  = $io->lock( { file => $map } );

if ($r) { 
    $tool->print_ok();
}
else {
    $tool->print_error($io->error);
}

sleep 1;

$tool->set_title("file unlock");
$r = $io->unlock( { file => '/tmp/fml5' });
if ($r) { 
    $tool->print_ok();
}
else {
    $tool->print_error($io->error);
}

exit 0;
