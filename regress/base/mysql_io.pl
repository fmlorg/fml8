#!/usr/pkg/bin/perl
#
# $Id$
#

use strict;
use IO::Adapter::MySQL::toymodel;

my $obj = new IO::Adapter::MySQL::toymodel { ml_name => 'elena' };

$obj->open({
    sql_user          => 'fukachan',
    sql_user_password => '',
});

while ($_ = $obj->getline) {
    print $_, "\n";
}

$obj->close;

