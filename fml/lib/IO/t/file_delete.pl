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
my $map      = "file:$file";
my $buffer   = 'root';

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file delete");

# prepare
system "head -1 $org_file | tr ':' ' ' > $tmpf";
system "cat $org_file | tr ':' ' ' > $file";

# orignal
my $orgbuf = $tool->get_content($file);

# append
use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->delete( $buffer ) || croak("cannot add to $map");
if ($obj->error) { croak( $obj->error );}

# verify the result
# assemble the original from the deleted line and modified file itself.
my $buf = $tool->get_content($tmpf) . $tool->get_content($file);

$tool->diff($buf, $orgbuf);

exit 0;
