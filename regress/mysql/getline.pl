#!/usr/pkg/bin/perl
#
# $Id$
#

use strict;
use IO::Adapter::MySQL;

my $obj = new IO::Adapter::MySQL { ml_name => 'elena' };

$obj->open({
    sql_user          => 'fukachan',
    sql_user_password => 'uja',
});

while ($_ = $obj->getline) {
    print $_, "\n";
}

$obj->close;

