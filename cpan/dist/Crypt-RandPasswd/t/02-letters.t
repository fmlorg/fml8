#!perl

use strict;
use warnings;
use Crypt::RandPasswd;
use Test::More 0.88 tests => 20;

my $word;
my $length;
my $min_length;
my $max_length;

for ($length = 10; $length < 20; $length++) {
    $word = Crypt::RandPasswd->letters($length, $length);
    ok(length($word) == $length && $word =~ /^[a-z]+$/,
       "create random letter string of length $length");
}

for ($min_length = 5; $min_length < 15; $min_length++) {
    $max_length = $min_length + 5;
    $word = Crypt::RandPasswd->letters($min_length, $max_length);
    ok(length($word) >= $min_length && length($word) <= $max_length && $word =~ /^[a-z]+$/,
       "create random letter string of length $min_length .. $max_length");
}
