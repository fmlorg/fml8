#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#

use strict;
use Carp;
use lib qw(../../cpan/lib lib);
use Mail::Message;

my $test_mode = $ENV{'test_mode'} ? 1 : 0;

for my $f (@ARGV) {
    print "\n\n\n";
    print "=" x 60;
    print "\n// $f \n\n";

    my $fd  = new FileHandle $f;
    my $msg = Mail::Message->parse( {
        fd           => $fd,
        header_class => 'FML::Header',
    });

    print $msg->whole_message_as_str({
	indent       => '   ',
    });
    print "<\n\n";
}

exit 0;
