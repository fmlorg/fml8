#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML: replace.pl,v 1.2 2001/04/03 09:45:47 fukachan Exp $
#

use strict;
use Carp;

my $org_file = "/etc/passwd";
my $file     = "/tmp/passwd";
my $tmpf     = "/tmp/passwd.tmp";
my $map      = "file:". $file;
my $regexp   = '^root';
my $value    = '@root';

### MAIN ###
print "${map}->replace() ";

# prepare
system "sed 1d $org_file > $tmpf";
system "cp $org_file /tmp/";

# append
use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->replace( $regexp, $value ) || croak("cannot add to $map");
if ($obj->error) { croak( $obj->error );}

# verify the result
# assemble the original from the replaced line and modified file itself.
my $newbuf  = GetContent($file);
my $expbuf  = $value . "\n". GetContent($tmpf);

if ($expbuf eq $newbuf) {
    print " ... ok\n";
}
else {
    print " ... fail\n";
    system "diff -ub $org_file $file";
}


$map = 'unix.group:fml';
print "${map}->replace()    ... ";
$obj = new IO::Adapter $map;
eval q{ $obj->replace( $regexp, $value ); };
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
