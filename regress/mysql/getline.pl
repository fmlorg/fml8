#!/usr/pkg/bin/perl
#
# $Id$
#

use strict;
use Carp;
use IO::Adapter;

my $map = 'mysql:toymodel';


my $map_params = {
    $map => {
	sql_server    => 'localhost',
	user          => 'fukachan',
	user_password => 'uja',
	database      => 'fml',
	table         => 'ml',
	params        => {
	    ml_name   => 'elena',
	    file      => 'members',
	},
    },
};


my $obj = new IO::Adapter ($map, $map_params);

_dump($obj); print "\n";

$obj->open();
$obj->add( 'rudo@nuinui.net' );
$obj->close();

_dump($obj); print "\n";

$obj->open();
$obj->delete( 'rudo@nuinui.net' );
$obj->close();

_dump($obj); print "\n";

exit 0;


sub _dump
{
    my ($obj) = @_;

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
}
