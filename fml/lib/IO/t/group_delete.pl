#-*- perl -*-
#
#  Copyright (C) 2001,2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: delete.pl,v 1.6 2002/08/19 15:19:46 fukachan Exp $
#

use strict;
use Carp;

my $org_file = "/etc/passwd";
my $file     = "/tmp/passwd";
my $tmpf     = "/tmp/passwd.tmp";
my $buffer   = 'root';

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("group delete");

my $map = 'unix.group:fml';

use IO::Adapter;
my $obj = new IO::Adapter $map;
eval q{ $obj->delete( $buffer ); };
if ($@) {
    $tool->print_ok(); # XXX fail (non null $@) is ok here.
}
else {
    $tool->print_error($obj->error);
}

exit 0;
