#!/usr/bin/env perl
#
# $FML$
#

if (-f "/etc/postfix/virtual") {
    print "IO::Adapter::find() for /etc/postfix/virtual\n";

    use IO::Adapter;

    my $map = new IO::Adapter ("file:/etc/postfix/virtual");

    if (defined $map) {
	$map->open;

	print "# want is not specified.\n";
	my $r = $map->find('^nuinui');
	print $r, "\n";

	print "# want = key,value\n";
	my $r = $map->find('^nuinui', { want => 'key,value' } );
	print $r, "\n";

	print "# want = key\n";
	my $r = $map->find('^nuinui', { want => 'key' } );
	print $r, "\n";

    }
    else {
	use Carp;
	croak("undefined");
    }
}

exit 0;
