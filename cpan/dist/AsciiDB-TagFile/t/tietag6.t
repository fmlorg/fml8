#!./perl -w
# Test the 'limit cache size' feature

use AsciiDB::TagFile;
use vars qw(@TEST_SETTINGS);

$cacheSize = 10;
$records = 50;

print "1..3\n";

@TEST_SETTINGS = (CACHESIZE => $cacheSize);
push(@INC, 't');
require 'tietag.pl';
my $tieObj = tied(%tietag);

foreach (1..$records) {
	$tietag{"R$_"}{'a'} = $_;

	do { print "not "; last } 
		if (getDataRecordsCount($tieObj) > $cacheSize);
}

print "ok 1\n";

$tieObj->purge();
print "not " if (getDataRecordsCount($tieObj) != 0);

print "ok 2\n";

foreach (1..$records) {
	my $fieldA = $tietag{"R$_"}{'a'};
	my $fieldB = $tietag{"R$_"}{'b'};

	do { print "not "; last } 
		if (getDataRecordsCount($tieObj) > $cacheSize);
}

print "ok 3\n";

foreach (1..$records) {
	delete $tietag{"R$_"};
}

sub getDataRecordsCount {
	my ($obj) = @_;

	my $keyCount = scalar(keys %$obj);
	$keyCount - $obj->{_INTKEYCOUNT};
}
