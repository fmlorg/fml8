#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: copy.pl,v 1.4 2001/06/17 09:00:30 fukachan Exp $
#

use strict;
my $debug = defined $ENV{'debug'} ? 1 : 0;

unless (@ARGV) {
    use File::Utils qw(copy);
    copy("main.cf", "/tmp/main.cf");
}
else {
    my ($src, $dst) = @ARGV;

    use IO::File::Atomic;
    print "IO::File::Atomic->copy($src, $dst);\n";
    print "sleep 3;\n";
    sleep 3;
    my $status = IO::File::Atomic->copy($src, $dst) || die("fail to copy");
}

exit 0;
