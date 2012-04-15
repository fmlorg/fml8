use strict;
use Test::More tests => 17;
BEGIN { use_ok('Email::Find') }

my %Tests;
BEGIN {
    %Tests = (
#	'Hahah!  Use "@".+*@[132.205.7.51] and watch them cringe!'
#	    => '"@".+*@[132.205.7.51]',
	'What about "@"@foo.com?' => '"@"@foo.com',
	'Eli the Beared <*@qz.to>' => '*@qz.to',
#	'"@"+*@[132.205.7.51]'    => '+*@[132.205.7.51]',
	'somelongusername@aol.com' => 'somelongusername@aol.com',
	'%2Fjoe@123.com' => '%2Fjoe@123.com',
	'joe@123.com?subject=hello.' => 'joe@123.com',
    );
}

while (my($text, $expect) = each %Tests) {
    my($orig_text) = $text;
    my $found = find_emails($text, sub {
				is $_[0]->address, $expect, "Found $_[1]";
				return $_[1]
			    });
    is $found, 1, "  just one";
    is $text, $orig_text,    "  and replaced";
}

# Do all the tests again as one big block of text.
my $mess_text = join "\n", keys %Tests;
is find_emails($mess_text, sub { return $_[1] }), scalar keys %Tests, 'One big block';


# Tests for false positives.
my @FalseTests;
BEGIN {
    # No tests at the moment.
    @FalseTests = (
                  );
}

foreach my $f_text (@FalseTests) {
    my $orig_text = $f_text;
    ok( find_emails($f_text, sub {1}) == 0, "False positive: $f_text" );
    ok( $orig_text eq $f_text,              "  replaced" );
}
