#!/usr/bin/env perl
#
# $FML: log_structured_data.pl,v 1.1 2001/04/02 14:34:04 fukachan Exp $
#

my $debug = defined $ENV{'debug'} ? 1 : 0;

use File::LogStructuredData;
$db = new File::LogStructuredData { file => '/tmp/cache.txt' };

$db->append("rudo is pretty");

$values = $db->find( 'rudo' );

print "\n// rudo\n\n";
print join("\n", @$values), "\n";

my $value = $db->get_value( 'rudo' );

print "\n// rudo => $value\n\n";

exit 0;
