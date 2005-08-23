#!/usr/pkg/bin/perl
#
# $FML: getline.pl,v 1.10 2001/09/17 11:42:03 fukachan Exp $
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
print STDERR "* add rudo\@nuinui.net into current table\n";
$obj->open();
if ($obj->error()) { print $obj->error(), "\n";}
$obj->add( 'rudo@nuinui.net' );
if ($obj->error()) { print $obj->error(), "\n";}
$obj->close();
if ($obj->error()) { print $obj->error(), "\n";}
Test::dump_content($obj); print "\n";

# TEST 3. find
print STDERR "* find rudo\@nuinui.net from current table\n";
$obj->open();
if ($obj->error()) { print $obj->error(), "\n";}
my $s = $obj->find( 'rudo@nuinui.net' );
my $a = $obj->find( 'rudo@nuinui.net', { all => 1} );
if ($obj->error()) { print $obj->error(), "\n";}
print "FOUND: $s\n";
print "FOUND: (@$a)\n\n";

print STDERR "* find rudo\@example.com from current table\n";
if ($obj->error()) { print $obj->error(), "\n";}
my $s = $obj->find( 'rudo@example.com' );
my $a = $obj->find( 'rudo@example.com', { all => 1} );
if ($obj->error()) { print $obj->error(), "\n";}
print "FOUND: $s\n";
print "FOUND: (@$a)\n\n";

$obj->close();
if ($obj->error()) { print $obj->error(), "\n";}


# TEST 4.
print STDERR "* delete rudo\@nuinui.net from current table\n";
$obj->open();
if ($obj->error()) { print $obj->error(), "\n";}
$obj->delete( 'rudo@nuinui.net' );
if ($obj->error()) { print $obj->error(), "\n";}
$obj->close();
if ($obj->error()) { print $obj->error(), "\n";}
Test::dump_content($obj); print "\n";

exit 0;
