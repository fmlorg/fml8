#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

use strict;
use Carp;

my $org_file = "/etc/passwd";
my $file     = "/tmp/passwd";
my $map      = "file:". $file;
my $buffer   = time . $$ . "aho ";


### MAIN ###
print "file map ->add() ";

# prepare
system "cp $org_file /tmp/";


# append
use IO::MapAdapter;
my $obj = new IO::MapAdapter $map;
$obj->add( $buffer ) || croak("cannot add to $map");
if ($obj->error) { croak( $obj->error );}

# verify the result
my $orgbuf   = GetContent($org_file);
my $buf      = GetContent($file);

$orgbuf .= $buffer ."\n";

if ($buf eq $orgbuf) { 
    print " ... ok\n";
}
else {
    print " ... fail\n";
    system "diff -ub $org_file $file";
}

exit 0;


sub GetContent
{
    my ($file) = @_;
    my $buf;

    use FileHandle;
    my $fh = new FileHandle $file;
    while (<$fh>) { $buf .= $_;}
    close($fh);

    $buf;
}
