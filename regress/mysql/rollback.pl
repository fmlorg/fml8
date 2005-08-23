#!/usr/pkg/bin/perl
#
# $FML: rollback.pl,v 1.1 2001/09/17 11:42:24 fukachan Exp $
#

use strict;
use Carp;
use lib qw(../../regress/mysql ../../fml/lib ../../cpan/lib ../../img/lib);
use Test;
use IO::Adapter;
use FML::Config;

my $config = new FML::Config;
$config->load_file("../../fml/etc/default_config.cf.ja");
$config->set("ml_name",   "elena");
$config->set("ml_domain", "home.fml.org");

my $driver = $ARGV[0] || 'mysql';
my $map    = "$driver:fml";
print STDERR "TEST of \"IO::Adapter $map, \$config;\"\n\n";
my $obj    = new IO::Adapter $map, $config;
unless (defined $obj) { croak "cannot set up $map\n";}

# TEST 1.
print STDERR "* current table\n";
Test::dump_content($obj); print "\n";

# TEST 2.
print STDERR "* add ...\n";
$obj->open();
for (1 .. 10) {
    $obj->add( "add\-${_}\-ress\@nuinui.net" );
}
$obj->close();
Test::dump_content($obj); print "\n";

# TEST 3.
print STDERR "* rollback test ...\n";
Test::rollback($obj); print "\n";

# TEST 4.
print STDERR "* delete ...\n";
$obj->open();
for (1 .. 10) {
    $obj->delete( "add\-${_}\-ress\@nuinui.net" );
}
$obj->close();
Test::dump_content($obj); print "\n";

exit 0;
