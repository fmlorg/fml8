#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: file_map.pl,v 1.6 2002/04/01 23:41:14 fukachan Exp $
#

use strict;
use Carp;

my $file   = "/etc/passwd";
my $map    = "file:$file";

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file read");

my $orgbuf = $tool->get_content($file);
my $buf    = '';

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open || $tool->error("cannot open $map");
if ($obj->error) { $tool->error( $obj->error );}
while (my $x = $obj->getline) { $buf .= $x; }
$obj->close;

$tool->diff($orgbuf, $buf);

exit 0;
