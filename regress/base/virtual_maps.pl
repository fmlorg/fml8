#!/usr/bin/env perl
#
# $FML: virtual_maps.pl,v 1.1 2002/02/13 12:30:35 fukachan Exp $
#

use strict;
my $debug = defined $ENV{'debug'} ? 1 : 0;

if (-f "/etc/postfix/virtual") {
    print "IO::Adapter::find() for /etc/postfix/virtual\n";

    use IO::Adapter;

    my $map = new IO::Adapter ("file:/etc/postfix/virtual");

    if (defined $map) {
	$map->open;

	{
	    print "# want is not specified.\n";
	    my $r = $map->find('^nuinui');
	    print $r, "\n";
	}

	{
	    print "# want = key,value\n";
	    my $r = $map->find('^nuinui', { want => 'key,value' } );
	    print $r, "\n";
	}

	{
	    print "# want = key\n";
	    my $r = $map->find('^nuinui', { want => 'key' } );
	    print $r, "\n";
	}

    }
    else {
	use Carp;
	croak("undefined");
    }
}

exit 0;
