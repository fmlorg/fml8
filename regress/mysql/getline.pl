#!/usr/pkg/bin/perl
#
# $Id$
#

use strict;
use Carp;
use IO::Adapter::MySQL;

my $obj = new IO::Adapter::MySQL {
    sql_server        => 'localhost',
    sql_user          => 'fukachan',
    sql_user_password => 'uja',

    database   => 'fml',
    table      => 'ml',
    schema     => 'toymodel',

    ml_name    => 'elena',
};


if (defined $obj) {
    if (defined $obj->open() ) {
	while ($_ = $obj->getline()) {
	    print $_, "\n";
	}
	$obj->close;
    }
    else {
	croak("cannot open()");
    }
}
else {
    croak("cannot make object");
}

exit 0;
