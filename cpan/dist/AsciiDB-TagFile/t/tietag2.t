#!./perl -w

use AsciiDB::TagFile;

print "1..9\n";

push(@INC, 't');
require 'tietag.pl';
print "ok 1\n";

($tietag{'record1'}{'a'} eq 'Fa') or print "not ";
print "ok 2\n";

($tietag{'record2'}{'b'} eq 'Fb') or print "not ";
print "ok 3\n";

(exists $tietag{'record2'}) or print "not ";
print "ok 4\n";

(!exists $tietag{'NOEXISTS'}) or print "not ";
print "ok 5\n";

# Bug: record copy not working
$tietag{'record1'} = $tietag{'record1'};
$tietag{'record3'} = $tietag{'record1'};
$tietag{'record3'}{'a'} = 'AValueForRecord3';
($tietag{'record3'}{'a'} ne $tietag{'record1'}{'a'}) or print "not ";
print "ok 6\n";

($tietag{'record3'}{'b'} eq $tietag{'record1'}{'b'}) or print "not ";
print "ok 7\n";

# Bug: 0 values not written
($tietag{'record1'}{'zero'} eq '0') or print "not ";
print "ok 8\n";

# Encode/Decode: Without this feature special characters like '/'
# can't be used in a key, becase the produce invalid filenames
($tietag{'string/string'}{'zero'} eq '0') or print "not ";
print "ok 9\n";
