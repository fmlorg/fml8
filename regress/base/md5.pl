#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: md5.pl,v 1.5 2001/12/23 03:01:27 fukachan Exp $
#

use strict;
use Carp;

my $debug = defined $ENV{'debug'} ? 1 : 0;
my $file  = shift || '/etc/group';
my $body  = ''; 

use FileHandle;
my $fh = new FileHandle $file;
while (<$fh>) { $body .=  $_;}
close($fh);

use Mail::Message::Checksum;
my $p = new Mail::Message::Checksum;

my $internal = $p->md5( \$body );
my $external = program($file);

print "Mail::Message::Checksum::md5 ... ";
print (($internal eq $external) ? "ok" : "fail");
print "\n";

exit 0;



sub program
{
    my ($file) = @_;
    my (@x) = ();

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
