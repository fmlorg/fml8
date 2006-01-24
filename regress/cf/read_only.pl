#!/usr/bin/env perl
#
# $FML: read_only.pl,v 1.1 2002/07/22 09:38:40 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib);
use FML::Config;

my $debug  = defined $ENV{'debug'} ? 1 : 0;
my $value  = 'a	b c READ_ONLY($map)';

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("config.cf READ_ONLY");

# test 1: 
#         READ_ONLY(x y) -> READ_ONLY(x) READ_ONLY(y)
#
my $config = new FML::Config;
$config->set( 'map',  'x y' );
$config->set( 'test', $value );
if ( $config->{ test } =~ /READ_ONLY\(x\)\s+READ_ONLY\(y\)/) {
    $tool->print_ok();
}
else {
    $tool->print_error();
}


# test 2: 
#         READ_ONLY(x y z) -> READ_ONLY(x) READ_ONLY(y) READ_ONLY(z)
#
my $config = new FML::Config;
$config->set( 'map',  'x y z' );
$config->set( 'test', $value );
if ( $config->{ test } =~ /READ_ONLY\(x\)\s+READ_ONLY\(y\)\s+READ_ONLY\(z\)/) {
    $tool->print_ok();
}
else {
    $tool->print_error($config->{ test });
}

1;
