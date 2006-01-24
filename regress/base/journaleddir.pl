#!/usr/bin/env perl
#
# $FML: journaleddir.pl,v 1.7 2002/08/03 10:33:27 fukachan Exp $
#

BEGIN {
    my $debug = defined $ENV{'debug'} ? 1 : 0;
    $| = 1; 
    print "Tie::JournaledDir init  journaleddir ...\n" if $debug;
};

use Tie::JournaledDir;

$| = 1; 

my $key   = shift || 'uja';
my $unit  = shift || 2;
my $dir   = "/tmp/fml5/jd";
my $debug = defined $ENV{'debug'} ? 1 : 0;

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("Tie::JournaledDir");

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

# 1.1 write/read
$tool->set_title("Tie::JournaledDir write [1]");
&_write($testpat);
&_read($testpat);

# 1.2 write/read
$tool->set_title("Tie::JournaledDir write [2]");
&_write2($testpat);
&_write($testpat);
&_write2($testpat);
&_read($testpat);

# 2. keys
$tool->set_title("Tie::JournaledDir keys");
&_keys($testpat);

# 3. get_all_values()
$tool->set_title("Tie::JournaledDir get_all_values");
&_get_all_values($testpat);

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

    print "check keys and values " if $debug;
    for my $k (keys %db) {
	print "." if $debug;
	if (defined $db{$k}) {
	    if ($db{$k} ne $pat->{$k}) {
		if ($debug) {
		    print "($k) differs: [";
		    print $db{$k};
		    print "] != [";
		    print $pat->{$k};
		    print "]\n";
		}
		$error++;
	    }

	    delete $found{$k};
	}
    }

    for (keys %found) {
	$error++;
	print "$_ is not found in journaled dir/ ?\n";
    }

    if ($error) {
	$tool->print_error();
    }
    else {
	$tool->print_ok();
    }

    untie %db;

    if ($debug) {
	system "ls -l $dir";
	print "\n";
    }
}


sub _write
{
    my ($pat, $mode) = @_;

    print "write journaleddir " if $debug;
    for my $key (keys %$pat) {
	tie %db, 'Tie::JournaledDir', { 
	    unit => $unit,
	    dir  => $dir,
	};

	$db{ $key } = $pat->{ $key };
	print "$key " if $debug;

	# XXX use several files in dir/
	print "." if $debug;
	sleep 1;

	untie %db;
    }

    print " done\n" if $debug;
}


sub _write2
{
    my ($pat, $mode) = @_;

    tie %db, 'Tie::JournaledDir', { 
	unit => $unit,
	dir  => $dir,
    };

    sleep 1;

    my $time  = time;
    my $key   = 'rudo';
    my $value = "rudo $time last";

    $db{ $key } = $pat->{ $key } = $value;
    print "$key " if $debug;

    # XXX use several files in dir/
    print "." if $debug;
    sleep 1;

    untie %db;
}


sub _keys
{
    my ($k, $v);
    my $raw_hash = {};

    # raw access
    use FileHandle;
    use DirHandle;
    my $dh = new DirHandle $dir;
    while ($dh->read) {
	if (-f "$dir/$_") {
	    my $fh = new FileHandle "$dir/$_";
	    if (defined $fh) {
		while (<$fh>) {
		    ($k, $v) = split(/s+/, $_, 2);
		    $raw_hash->{ $k } = $v; 
		}
		$fh->close();
	    }
	}
    }

    # go!
    tie %db, 'Tie::JournaledDir', { 
	unit => $unit,
	dir  => $dir,
    };

    my $len_orig = length(keys %$raw_access);
    my $len      = length(keys %db);

    $tool->diff($len, $len_orig);

    untie %db;
}


sub _get_all_values
{
    unless ($debug) {
	return;
    }

    # go!
    tie %db, 'Tie::JournaledDir', { 
	unit => $unit,
	dir  => $dir,
    };

    my @k = keys %db;

    untie %db;

    my $obj = new Tie::JournaledDir { 
	unit => $unit,
	dir  => $dir,
    };

    my $a = $obj->get_all_values_as_hash_ref();
    use Data::Dumper;
    print Dumper( $a );
}
