#!./perl -w

use AsciiDB::TagFile;

print "1..5\n";

push(@INC, 't');
require 'tietag.pl';
my $tieObj = tied(%tietag);
print "ok 1\n";

delete $tietag{'record1'};
print "not " if -f $tieObj->fileName('record1');
print "ok 2\n";

delete $tietag{'record3'};
print "not " if -f $tieObj->fileName('record3');
print "ok 3\n";

delete $tietag{'string/string'};
print "not " if -f $tieObj->fileName('string/string');
print "ok 4\n";

# Check point: Current record keys should be what expected

my $notOk = 0;
my @realKeys = sort keys %tietag;
my @testKeys = sort qw(record2);
print STDERR "\nKEYS: @realKeys\n" if $ENV{DEBUG};
while (@realKeys || @testKeys) {
	my $realKey = shift @realKeys;
	my $testKey = shift @testKeys;

	if (!defined $realKey || !defined $testKey || $realKey ne $testKey) {
		$notOk = 1;
		last;
	}
}

print "not " if $notOk;
print "ok 5\n";
