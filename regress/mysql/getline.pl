#!/usr/pkg/bin/perl
#
# $Id$
#

use strict;
use Carp;
use IO::MapAdapter;

my $map = 'mysql:toymodel';
my $q   = "select address from ml where ml='elena' and file='members'";
my $map_params = {
    $map => {
	config => {
	    sql_server    => 'localhost',
	    user          => 'fukachan',
	    user_password => 'uja',
	    database      => 'fml',
	    table         => 'ml',
	},
	query  => {
	    getline        => $q,
	    get_next_value => $q,
	    add            => "insert into ml values ()",
	},
    },
};


my $obj = new IO::MapAdapter ($map, $map_params);

if (defined $obj) {
    if (defined $obj->open()) {
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
