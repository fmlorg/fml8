#!/usr/local/bin/perl
#
# $FML: mime.pl,v 1.6 2001/06/17 09:00:30 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib);
use FML::Config;

my $config = new FML::Config;
my @prev_x = ();
my $i = 0;

for my $f (@ARGV) {
    $config->overload($f);

    my $x = $config->{ 'x' };
    print STDERR "   x = $x (loaded $f)\n";

    # save values
    $prev_x[ $i ] = $x; $i++;
}

$prev_x[ 0 ] =~ s/xxx/yyy/;

if ($prev_x[ 0 ] eq $prev_x[ 1]) {
    print STDERR "ok\n";
}
else {
    print STDERR "fail\n";
}

1;
