# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use lib 'lib';
use Crypt::RandPasswd;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my( $minlen, $maxlen ) = ( 6, 8 );

my( $unhyphenated_word, $hyphenated_word ) = Crypt::RandPasswd->word( $minlen, $maxlen );
print "ok 2\n";

$unhyphenated_word = Crypt::RandPasswd->word( $minlen, $maxlen );
print "ok 3\n";

$unhyphenated_word = Crypt::RandPasswd->letters( $minlen, $maxlen );
print "ok 4\n";

$unhyphenated_word = Crypt::RandPasswd->chars( $minlen, $maxlen );
print "ok 5\n";

