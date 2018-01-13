#!perl

use strict;
use warnings;
use Crypt::RandPasswd;
use Test::More 0.88 tests => 20;

my $word;
my $length;
my $min_length;
my $max_length;
my @chars;
my $char;
my $regexp;

for ($length = 10; $length < 20; $length++) {
    $word = Crypt::RandPasswd->chars($length, $length);
    ok(length($word) == $length && valid_chars($word),
       "create random letter string of length $length");
}

for ($min_length = 5; $min_length < 15; $min_length++) {
    $max_length = $min_length + 5;
    $word = Crypt::RandPasswd->chars($min_length, $max_length);
    ok(length($word) >= $min_length && length($word) <= $max_length && valid_chars($word),
       "create random letter string of length $min_length .. $max_length");
}

sub valid_chars
{
    my $word = shift;

    foreach my $char (split('', $word)) {
        return 0 if ord($char) < ord('!') || ord($char) > ord('~');
    }
    return 1;
}
