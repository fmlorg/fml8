#!/usr/bin/env perl
#
# $FML: test.overload.pl,v 1.2 2002/04/18 14:18:09 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib);
use FML::Config;

my $debug  = defined $ENV{'debug'} ? 1 : 0;
my $value  = 'a	b c READ_ONLY($map)';


# test 1: 
#         READ_ONLY(x y) -> READ_ONLY(x) READ_ONLY(y)
#
my $config = new FML::Config;
$config->set( 'map',  'x y' );
$config->set( 'test', $value );
if ( $config->{ test } =~ /READ_ONLY\(x\)\s+READ_ONLY\(y\)/) {
    print "ok\n";
}
else {
    print "fail\n";
}


# test 2: 
#         READ_ONLY(x y z) -> READ_ONLY(x) READ_ONLY(y) READ_ONLY(z)
#
my $config = new FML::Config;
$config->set( 'map',  'x y z' );
$config->set( 'test', $value );
if ( $config->{ test } =~ /READ_ONLY\(x\)\s+READ_ONLY\(y\)\s+READ_ONLY\(z\)/) {
    print "ok\n";
}
else {
    print "fail\n";
    print $config->{ test }, "\n";
}

1;
