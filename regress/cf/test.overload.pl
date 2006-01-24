#!/usr/bin/env perl
#
# $FML: test.overload.pl,v 1.3 2002/07/22 09:38:10 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib);
use FML::Config;

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("config.cf overload");

my $debug  = defined $ENV{'debug'} ? 1 : 0;
my $config = new FML::Config;
my @prev_x = ();
my $i      = 0;

for my $f (@ARGV) {
    $config->overload($f);

    my $x = $config->{ 'x' };
    print STDERR "   x = $x (loaded $f)\n" if $debug;

    # save values
    $prev_x[ $i ] = $x; $i++;
}

$prev_x[ 0 ] =~ s/xxx/yyy/;

$tool->diff($prev_x[ 0 ], $prev_x[ 1 ]);

exit 0;
