#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: basic_io.pl,v 1.4 2001/04/13 04:34:07 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib ../../fml/lib);
use Mail::Message;
use FileHandle;

my $sender = 'elena-admin@sapporo.iij.ad.jp';
my $rcpt   = 'fukachan@sapporo.iij.ad.jp';
my $array  = [ $rcpt ];

for my $file (@ARGV) {
    my $fh  = new FileHandle $file;
    my $msg = Mail::Message->parse( { fd => $fh } );

    use FML::Mailer;
    my $obj = new FML::Mailer;
    $obj->send( {
	sender    => $sender,
	recipient => $rcpt,
	message   => $msg,
    });
}

exit 0;
