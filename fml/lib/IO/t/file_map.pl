#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: file_map.pl,v 1.4 2001/05/04 14:32:34 fukachan Exp $
#

use Carp;

$file = "/etc/passwd";
$map  = "file:". $file;

open($file, $file) || croak($!); 
while (1) {
    $p = sysread($file, $_, 4096);
    last unless $p;
    $orgbuf .= $_;
}
close($file);

use IO::Adapter;
$obj = new IO::Adapter $map;
$obj->open || croak("cannot open $map");
if ($obj->error) { croak( $obj->error );}
while ($x = $obj->getline) { $buf .= $x; }
$obj->close;

if ($orgbuf eq $buf) {
    print STDERR "$map reading ... ok\n";
}
else {
    exit 1;
}

exit 0;
