#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: delete.pl,v 1.5 2002/04/01 23:41:14 fukachan Exp $
#

use strict;
use Carp;

my $org_file = "/etc/passwd";
my $file     = "/tmp/passwd";
my $tmpf     = "/tmp/passwd.tmp";
my $map      = "file:". $file;
my $buffer   = 'root';

### MAIN ###
print "${map}->delete() ";

# prepare
system "head -1 $org_file | tr ':' ' ' > $tmpf";
system "cat $org_file | tr ':' ' ' > $file";

# orignal
my $orgbuf   = GetContent($file);

# append
use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->delete( $buffer ) || croak("cannot add to $map");
if ($obj->error) { croak( $obj->error );}

# verify the result
# assemble the original from the deleted line and modified file itself.
my $buf      = GetContent($tmpf) . GetContent($file);

if ($buf eq $orgbuf) {
    print " ... ok\n";
}
else {
    print " ... fail <$buf> ne <$orgbuf>\n";
}


$map = 'unix.group:fml';
print "${map}->delete()    ... ";
$obj = new IO::Adapter $map;
eval q{ $obj->delete( $buffer ); };
if ($@) {
    print "ok\n"; # XXX fail (non null $@) is ok here.
}
else {
    print "fail"        unless $@;
    print "<", $obj->error, ">" if $obj->error;
    print "\n";
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
