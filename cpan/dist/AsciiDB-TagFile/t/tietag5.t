#!./perl -w
# Test bug fixed in 1.03
# 	Create record
#	Delete record
#	Destroy record (no file should be created at this point)

use AsciiDB::TagFile;

print "1..2\n";

my $fileName;

{ # Open scope

push(@INC, 't');
require 'tietag.pl';
my $tieObj = tied(%tietag);
print "ok 1\n";

$tietag{'removed'}{'a'} = 1;
delete $tietag{'removed'};

$fileName = $tieObj->fileName('removed');
} # Close scope

print "not " if -e $fileName;
print "ok 2\n";
