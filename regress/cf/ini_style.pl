#!/usr/bin/env perl
#
# $FML: read_only.pl,v 1.1 2002/07/22 09:38:40 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib);
use FML::Config;

my $debug  = defined $ENV{'debug'} ? 1 : 0;
my $map    = 'mysql:fml';
my $config = new FML::Config;

for my $file (@ARGV) {
    $config->load_file($file);
}

my $hash_ref = { 1 => 2 };
my $p        = $config->{ '[mysql:fml]' };

use Data::Dumper;
print Dumper( $hash_ref );
print Dumper( $p );
print "\n";

1;
