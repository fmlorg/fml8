#!/usr/bin/env perl
#
# $FML: journaleddir.pl,v 1.3 2001/08/22 21:58:50 fukachan Exp $
#

BEGIN {
    print "init  journaleddir ...\n";
};

use Tie::JournaledDir;

$| = 1; 

my $key  = shift || 'uja';
my $unit = shift || 2;
my $dir  = "/tmp/fml5/jd";


if (-d $dir) {
    use DirHandle;
    my $dh = new DirHandle $dir;
    for ($dh->read) { unlink "$dir/$_" if -f "$dir/$_";}
}
else {
    system "mkdir -p $dir" unless -d $dir;
}

my $testpat = {
    'rudo'   => $$,
    'rudo$$' => time(),
    $$       => "elena",
    time()   => "kumiko",
};

for my $k (keys %$testpat) {
    my ($buf, $newkey);
    chop($buf = `/usr/games/fortune | sed 1q`);
    $buf =~ s/^\s*//;
    if ($buf =~ /^(\S+)/) { $newkey = $1;}
    $testpat->{ $k }         = $buf;
    $testpat->{ $k.$newkey } = $buf;
}

&_write($testpat);
&_read($testpat);

exit 0;


sub _read
{
    my ($pat) = @_;

    tie %db, 'Tie::JournaledDir', { 
	unit => $unit,
	dir  => $dir,
    };

    my $error = 0;
    my %found = %$pat;

    print "check keys and values ";
    for my $k (keys %db) {
	print ".";
	if (defined $db{$k}) {
	    if ($db{$k} ne $pat->{$k}) {
		print "($k) differs: [";
		print $db{$k};
		print "] != [";
		print $pat->{$k};
		print "]\n";
		$error++;
	    }

	    delete $found{$k};
	}
    }

    for (%found) {
	$error++;
	print "$_ is not found in journaled dir/ ?\n";
    }

    if ($error) {
	print " fail\n";
    }
    else {
	print " ok\n";
    }

    untie %db;

    system "ls -l $dir";
    print "\n";
}


sub _write
{
    my ($pat) = @_;

    print "write journaleddir ";
    for my $key (keys %$pat) {
	tie %db, 'Tie::JournaledDir', { 
	    unit => $unit,
	    dir  => $dir,
	};

	$db{ $key } = $pat->{ $key };
	print "$key ";
	sleep 1;

	untie %db;
    }
    print " done\n";
}
