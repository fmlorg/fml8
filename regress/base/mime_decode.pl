#!/usr/bin/env perl
#
# $FML: mime_decode.pl,v 1.1 2001/10/19 13:16:19 fukachan Exp $
#

use strict;
use lib qw(../../cpan/lib ../../fml/lib ../../im/lib);
use MIME::Base64;

my $debug = defined $ENV{'debug'} ? 1 : 0;
my $buf   = '';

while (<>) {
	$buf .= $_; 
}

print decode_base64($buf);

exit 0;
