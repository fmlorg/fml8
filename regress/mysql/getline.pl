#!/usr/pkg/bin/perl
#
# $Id$
#

use strict;
use Carp;
use IO::MapAdapter;

my $map = 'mysql:toymodel';

my $q_getline = "select address from ml where ml='elena' and file='members'";
my $q_add     = "insert into ml values ('elena', 'members', '\%s', 0, 0)";
my $q_delete  = "delete from ml where ml='elena' and address='\%s'";

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
	    getline        => $q_getline,
	    get_next_value => $q_getline,
	    add            => $q_add,
	    delete         => $q_delete,
	},
    },
};


my $obj = new IO::MapAdapter ($map, $map_params);

_dump($obj); print "\n";

$obj->open();
$obj->add( 'rudo' );
$obj->close();

_dump($obj); print "\n";

$obj->open();
$obj->delete( 'rudo' );
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
