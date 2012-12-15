#!/usr/bin/env perl
#
#  Copyright (C) 2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: date2unixtime.pl,v 1.5 2006/01/24 11:33:04 fukachan Exp $
#

use strict;
use Mail::Message::Date;

my $debug = defined $ENV{'debug'} ? 1 : 0;

# require 'ctime.pl';
use Time::localtime;

my $t    = time;
my $date = ctime( $t );
$date =~ s/[\s\n]*$//;

my $dp = new Mail::Message::Date;
my $tx = $dp->date_to_unixtime( $date );

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("Mail::Message::Date");

if ($debug) {
    print STDERR "Mail::Message::Date ";
    print STDERR "(date -> unixtime): $t => $date => $tx\n";
}

$tool->diff($t, $tx);

exit 0;
