#!/usr/pkg/bin/perl
#
# $FML$
#

use strict;
use lib qw(../../cpan/lib ../../fml/lib ../../im/lib);
use MIME::Base64;

my $buf = '';

while (<>) {
	$buf .= $_; 
}

print encode_base64($buf);

exit 0;
