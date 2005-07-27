#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: make.pl,v 1.1 2001/05/06 13:00:11 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../cpan/lib ../../fml/lib);

#
# make a plain message;
#

use Mail::Message::Compose;
my $msg = Mail::Message::Compose->new(
				      From     =>'fukachan@fml.org',
				      To       =>'rudo@nuinui.net',
				      Cc       =>'kenken@nuinui.net',
				      Subject  =>'Helloooooo, nurse!',
				      Type     =>'text/plain',
				      Path     =>'main.cf',
				      );

$msg->attr('content-type.charset' => 'us-ascii');

print $msg->as_string;

exit 0;
