#!/usr/pkg/bin/perl
#
# $FML: getline.pl,v 1.9 2001/06/17 09:00:31 fukachan Exp $
#

use strict;
use Carp;
use IO::Adapter;

my $map = 'mysql:toymodel';


my $map_params = {
    $map => {
	sql_server    => 'mysql.home.fml.org',
	user          => 'fukachan',
	user_password => 'uja',
	database      => 'ML',
	table         => 'ml',
	params        => {
	    ml_name   => 'elena',
	    file      => 'members',
	},
    },
};


my $obj = new IO::Adapter ($map, $map_params);

unless (defined $obj) {
   croak "cannot set up $map\n";
}

print STDERR "* current table\n";
_dump($obj); print "\n";

print STDERR "* add rudo\@nuinui.net into current table\n";
$obj->open();
$obj->add( 'rudo@nuinui.net' );
$obj->close();

_dump($obj); print "\n";

print STDERR "* delete rudo\@nuinui.net from current table\n";
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
		my $y = $obj->eof ? "y" : "n";
		print "<", $obj->getpos, "(eof=$y)> ";
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
