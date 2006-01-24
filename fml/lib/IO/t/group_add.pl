#-*- perl -*-
#
#  Copyright (C) 2001,2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: append.pl,v 1.6 2002/04/01 23:41:14 fukachan Exp $
#

use strict;
use Carp;
use FML::Test::Utils;

my $map  = 'unix.group:fml';

my $tool = new FML::Test::Utils;
$tool->set_title("group add ($map)");

use IO::Adapter;
my $obj = new IO::Adapter $map;
eval q{ $obj->add( $buffer ); };
if ($@) {
    $tool->print_ok(); # XXX fail (non null $@) is ok here.
}
else {
    $tool->print_error($obj->error());
}

exit 0;
