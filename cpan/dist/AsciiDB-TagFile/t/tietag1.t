#!./perl -w

use UNIVERSAL qw(isa);

use AsciiDB::TagFile;

print "1..6\n";

push(@INC, 't');
require 'tietag.pl';
print "ok 1\n";

$tietag{'record1'}{'a'} = 'Fa';
$tietag{'record1'}{'b'} = 'F1b';
$tietag{'record2'}{'b'} = 'Fb';
tied(%tietag)->sync();
print "ok 2\n";

($tietag{'record1'}{'a'} eq 'Fa') or print "not ";
($tietag{'record2'}{'b'} eq 'Fb') or print "not ";
print "ok 3\n";

isa(tied(%tietag), 'AsciiDB::TagFile') or print "not ";
print "ok 4\n";

# Bug: 0 values not written
$tietag{'record1'}{'zero'} = '0';
($tietag{'record1'}{'zero'} eq '0') or print "not ";
print "ok 5\n";

# Encode/Decode: Without this feature special characters like '/'
# can't be used in a key, becase the produce invalid filenames
$tietag{'string/string'}{'zero'} = '0';
($tietag{'string/string'}{'zero'} eq '0') or print "not ";
print "ok 6\n";
