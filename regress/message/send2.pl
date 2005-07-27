#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: send2.pl,v 1.4 2001/05/09 00:55:56 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib ../../fml/lib);
use Mail::Message;
use FileHandle;
require 'ctime.pl';

my $sender = 'elena-admin@sapporo.iij.ad.jp';
my $rcpt   = 'fukachan@sapporo.iij.ad.jp';
my $array  = [ $rcpt ];
my $data   = "test\n";
my $date   = &ctime(time);
my $tmpf   = "/tmp/buf$$";

chop $date;

use Mail::Message::Compose;
my $msg = Mail::Message::Compose->new(
  From    => $sender,
  To      => $rcpt,
  Subject => 'test',
  Date    => $date,
  Type    => 'multipart/mixed',
  'X-FML-Version' => 'fml 5.0',
);

$msg->attach(Type => 'text/plain; charset=us-ascii',
	     Data => $data);

print "-" x 60; print "\n";

use Mail::Delivery::Queue;
my $obj = new Mail::Delivery::Queue { directory => "/tmp" };
$obj->in( $msg ) || croak("fail to queue in");
$obj->setrunnable() || croak("fail to activate queue");

use FML::Mailer;
my $m = new FML::Mailer;
$m->send( {
    sender    => $sender,
    recipient => $rcpt,
    file      => $obj->filename(),
});

$obj->remove;

exit 0;
