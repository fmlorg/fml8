#!/usr/pkg/bin/perl
#
# $FML: mime_encode.pl,v 1.1 2001/09/23 14:32:34 fukachan Exp $
#

use strict;
use lib qw(../../cpan/lib ../../fml/lib ../../im/lib);
use MIME::Base64;

my $buf = '';

while (<>) {
	$buf .= $_; 
}

print decode_base64($buf);

exit 0;
