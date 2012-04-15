use strict;
use Test::More 'no_plan'; # XXX
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
    my $cb = sub {
	is $_[0]->address, $expect, "Found $_[1]";
	return $_[1];
    };
    my $finder = Email::Find->new($cb);
    my $found = $finder->find(\$text);
    is $found, 1, "  just one";
    is $text, $orig_text,    "  and replaced";
}

