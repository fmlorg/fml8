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

my $org_file = "/etc/passwd";
my $file     = "/tmp/passwd";
my $map      = "file:$file";
my $buffer   = sprintf("%s.%s.%s", time, $$, "aho");

#
# test 1.
#
my $tool = new FML::Test::Utils;
$tool->set_title("file add");
$tool->copy($org_file, $file);

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->add( $buffer ) || $tool->error("cannot add to $map");
if ($obj->error) { $tool->error( $obj->error );}

my $orgbuf   = $tool->get_content($org_file);
$orgbuf     .= $buffer ."\n";
my $buf      = $tool->get_content($file);
$tool->diff($buf, $orgbuf);

exit 0;
