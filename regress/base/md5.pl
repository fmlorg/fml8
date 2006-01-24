#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: md5.pl,v 1.6 2002/04/18 14:18:07 fukachan Exp $
#

use strict;
use Carp;

my $debug = defined $ENV{'debug'} ? 1 : 0;
my $file  = shift || '/etc/group';
my $body  = ''; 

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("md5 checksum");

use FileHandle;
my $fh = new FileHandle $file;
while (<$fh>) { $body .=  $_;}
close($fh);

use Mail::Message::Checksum;
my $p = new Mail::Message::Checksum;

my $internal = $p->md5( \$body );
my $external = program($file);

$tool->set_title("Mail::Message::Checksum::md5");
$tool->diff($internal, $external);

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
