#!/usr/local/bin/perl

use FML::List::Read;
use Benchmark;

$h = new FML::List::Read(
			 'type' => 'nis',
			 'list' => 'members',
			 'file' => '/etc/motd'
			 );

print STDERR "--- open motd\n";
$fh = $h->open;
if (defined $fh) {
    while (<$fh>) { print STDERR $_;}
    $fh = $h->close;
}

$h = new FML::List::Read();
print STDERR "--- open test.pl\n";


$fh = $h->open("/usr/share/dict/web2");
$t0 = new Benchmark;

if (defined $fh) {
    my $outfh = new FileHandle "> /var/tmp/uja";
    if (defined $outfh) {
	# $h->put($outfh);
	$h->put;
	$outfh->close;
    }
    $fh = $h->close;
}
$t1 = new Benchmark;
print STDERR timestr( timediff($t1, $t0) ), "\n";


print STDERR "--- standard \n";
$fh = $h->open("/usr/share/dict/web2");
$t0 = new Benchmark;
my $outfh = new FileHandle "> /var/tmp/uja2";
if (defined $fh) {
    while (<$fh>) { print $outfh $_;}
    $fh = $h->close;
}
$t1 = new Benchmark;
print STDERR timestr( timediff($t1, $t0) ), "\n";

exit 0;
