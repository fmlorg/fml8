#!./perl -w
# Test the READONLY feature

use AsciiDB::TagFile;
use vars qw(@TEST_SETTINGS);

print "1..3\n";

@TEST_SETTINGS = (READONLY => 1);
push(@INC, 't');
require 'tietag.pl';
my $tieObj = tied(%tietag);
print "ok 1\n";

$tietag{'record2'}{'b'} = 'NOTVALID';
($tietag{'record2'}{'b'} eq 'Fb') or print "not ";
print "ok 2\n";

delete $tietag{'record2'};
print "not " if ! -f $tieObj->fileName('record2');
print "ok 3\n";

unlink $tieObj->fileName('record2') if -f $tieObj->fileName('record2');
