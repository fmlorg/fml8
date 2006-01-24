#!/usr/bin/env perl
#
#  Copyright (C) 2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: journaledfile.pl,v 1.5 2002/08/03 10:33:27 fukachan Exp $
#

use strict;
use lib qw(../../fml/lib);
use Tie::JournaledFile;

$| = 1;

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("Tie::JournaledFile write");

#
# 1. read/write
#
my $debug = defined $ENV{'debug'} ? 1 : 0;
my %db   = ();
my $file = '/tmp/fml5/cache.txt';
my $buf  = '';
my $key  = "rudo$$";
chomp($buf = `date`);

tie %db, 'Tie::JournaledFile', { file => $file };
$db{ $key } = $buf;
untie %db;

print "   ", `ls -l $file` if $debug;

tie %db, 'Tie::JournaledFile', { file => $file };

print "verify written string ... " if $debug;
$tool->diff($db{ $key }, $buf);


#
# 2. keys
#
$tool->set_title("Tie::JournaledFile keys");

my @p = keys %db;
my $count_orig = ` awk '{print $1}' $file | sort | uniq | wc -l `;
$count_orig =~ s/\s+//g;
my $count = $#p + 1;

$tool->diff($count_orig, $count);

exit 0;
