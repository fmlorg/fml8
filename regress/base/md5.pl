#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: md5.pl,v 1.4 2001/06/17 09:00:29 fukachan Exp $
#

$file = shift || '/etc/group';

my $body; 

use FileHandle;
my $fh = new FileHandle $file;
while (<$fh>) { $body .=  $_;}
close($fh);

use Mail::Message::Checksum;
$p = new Mail::Message::Checksum;

$internal = $p->md5( \$body );
$external = program($file);

print "Mail::Message::Checksum::md5 ... ";
print (($internal eq $external) ? "ok" : "fail");
print "\n";

exit 0;



sub program
{
    my ($file) = @_;

    use IO::Handle;
    $fh = new IO::Handle;

    open($fh, "md5 $file|");
    while (<$fh>) {
	chop;
	(@x) = split(/\s*=\s*/);
    }
    close($fh);

    return $x[1];
}
