#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: send.pl,v 1.1 2001/05/05 13:50:59 fukachan Exp $
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

use Mail::Message::Queue;
my $obj = new Mail::Message::Queue { directory => "/tmp" };
$obj->in( $msg ) || croak("fail to queue in");
$obj->activate() || croak("fail to activate queue");

my $qf = $obj->queue_file();

use FML::Mailer;
my $m = new FML::Mailer;
$m->send( {
    sender    => $sender,
    recipient => $rcpt,
    file      => $qf,
});

$obj->remove;

exit 0;
