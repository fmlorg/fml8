#!/usr/local/bin/perl
#
# $FML$
#

use File::LogStructuredData;
$db = new File::LogStructuredData { file => '/tmp/cache.txt' };

$db->append("rudo is pretty");

$values = $db->find( 'rudo' );

print "\n// rudo\n\n";
print join("\n", @$values), "\n";

my $value = $db->get_value( 'rudo' );

print "\n// rudo => $value\n\n";

exit 0;
