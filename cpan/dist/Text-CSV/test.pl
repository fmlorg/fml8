# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::CSV;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# empty subclass test
#
package Empty_Subclass;
@ISA = qw(Text::CSV);
package main;
my $empty = Empty_Subclass->new();
if ($empty->version() and $empty->parse('') and $empty->combine('')) {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}

my $csv = Text::CSV->new();

if (! $csv->combine()) {  # fail - missing argument
  print "ok 3\n";
} else {
  print "not ok 3\n";  
}
if (! $csv->combine('abc', "def\n", 'ghi')) {  # fail - bad character
  print "ok 4\n";
} else {
  print "not ok 4\n";  
}
if ($csv->combine('') && ($csv->string eq q(""))) {  # succeed
  print "ok 5\n";
} else {
  print "not ok 5\n";  
}
if ($csv->combine('', '') && ($csv->string eq q("",""))) {  # succeed
  print "ok 6\n";
} else {
  print "not ok 6\n";  
}
if ($csv->combine('', 'I said, "Hi!"', '') &&
    ($csv->string eq q("","I said, ""Hi!""",""))) {  # succeed
  print "ok 7\n";
} else {
  print "not ok 7\n";  
}
if ($csv->combine('"', 'abc') && ($csv->string eq q("""","abc"))) {  # succeed
  print "ok 8\n";
} else {
  print "not ok 8\n";  
}
if ($csv->combine('abc', '"') && ($csv->string eq q("abc",""""))) {  # succeed
  print "ok 9\n";
} else {
  print "not ok 9\n";  
}
if ($csv->combine('abc', 'def', 'ghi') &&
    ($csv->string eq q("abc","def","ghi"))) {  # succeed
  print "ok 10\n";
} else {
  print "not ok 10\n";  
}
if ($csv->combine("abc\tdef", 'ghi') &&
    ($csv->string eq qq("abc\tdef","ghi"))) {  # succeed
  print "ok 11\n";
} else {
  print "not ok 11\n";  
}
if (! $csv->parse()) {  # fail - missing argument
  print "ok 12\n";
} else {
  print "not ok 12\n";  
}
if (! $csv->parse('"abc')) {  # fail - missing closing double-quote
  print "ok 13\n";
} else {
  print "not ok 13\n";  
}
if (! $csv->parse('ab"c')) {  # fail - double-quote outside of double-quotes
  print "ok 14\n";
} else {
  print "not ok 14\n";  
}
if (! $csv->parse('"ab"c"')) {  # fail - bad character sequence
  print "ok 15\n";
} else {
  print "not ok 15\n";  
}
if (! $csv->parse(qq("abc\nc"))) {  # fail - bad character
  print "ok 16\n";
} else {
  print "not ok 16\n";  
}
if (! $csv->status()) {  # fail - test #16 should have failed
  print "ok 17\n";
} else {
  print "not ok 17\n";  
}
if ($csv->parse(q(",")) and ($csv->fields())[0] eq ',') {  # success
  print "ok 18\n";
} else {
  print "not ok 18\n";  
}
if ($csv->parse(qq("","I said,\t""Hi!""","")) and
($csv->fields())[0] eq '' and
($csv->fields())[1] eq qq(I said,\t"Hi!") and
($csv->fields())[2] eq '') {  # success
  print "ok 19\n";
} else {
  print "not ok 19\n";  
}
if ($csv->status()) {  # success - test #19 should have succeeded
  print "ok 20\n";
} else {
  print "not ok 20\n";  
}
