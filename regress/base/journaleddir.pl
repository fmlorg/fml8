#!/usr/bin/env perl
#
# $FML$
#

use Tie::JournaledDir;

my $key  = shift || 'uja';
my $unit = 60;
my $dir  = "/tmp/fml5/jd";

system "mkdir -p $dir" unless -d $dir;
&_read();
&_write();

exit 0;


sub _read
{
    tie %db, 'Tie::JournaledDir', { 
	unit => $unit,
	dir  => $dir,
    };

    print "   $key => $db{ $key }\n";

    print "\n   keys: ";
    print join(" ", keys %db);
    print "\n";
}


sub _write
{
    tie %db, 'Tie::JournaledDir', { 
	unit => $unit,
	dir  => $dir,
    };

    my $x = `date`;
    chop $x;
    $db{ $key } = $x;

    untie %db;
}
