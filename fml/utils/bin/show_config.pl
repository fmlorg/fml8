#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use Getopt::Long;
my %option = ();

GetOptions(\%option, qw(debug! d! sgml! html! type=s));

$/ = "\n\n";

my $mode = $option{ sgml } ? 'sgml' : 'html';
my $type = $option{ type } || '';

pre($mode);

while (<>) {
    if ($type eq 'filter_rules') {
	print if /filter/o && not /ldap/o;
    }

    if ($type eq 'filter_size') {
	print if /size/o;
    }
}

post($mode);

exit 0;


sub pre
{
    print "<para>\n";
    print "<screen>\n";
}


sub post
{
    print "</screen>\n";
    print "</para>\n";
}
