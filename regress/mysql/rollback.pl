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

print STDERR "* add ...\n";
$obj->open();

for (1 .. 10) {
    $obj->add( "add\-${_}\-ress\@nuinui.net" );
}
$obj->close();

_dump($obj); print "\n";


print STDERR "* rollback test ...\n";
_rollback($obj); print "\n";

print STDERR "* regexp test ...\n";
$obj->close();
$obj->open();
$obj->replace('7', 7); print "\n";
$obj->close();

print STDERR "* delete ...\n";
$obj->open();

for (1 .. 10) {
    $obj->delete( "add\-${_}\-ress\@nuinui.net" );
}

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


sub _rollback
{
    my ($obj) = @_;
    my $done  = 0;

    if (defined $obj) {
	if (defined $obj->open()) {
	    while ($_ = $obj->getline()) {
		my $y = $obj->eof ? "y" : "n";
		print "<", $obj->getpos, "(eof=$y)> ";
		print $_, "\n";

		unless ($done) {
		    if ($obj->getpos == 4) {
			print STDERR "   skip to 6 \n";
			$obj->setpos(6);
			next;
		    }

		    if ($obj->getpos == 7) {
			print STDERR "   back to 3 \n";
			$obj->setpos(3);
			$done = 1;
		    }
		}
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
