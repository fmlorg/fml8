#!/usr/bin/env perl
#
# $FML$
#

use strict;
use File::Basename;
use vars qw(%opts);

my $debug = defined $ENV{'debug'} ? 1 : 0;

use Getopt::Std;
getopts('d', \%opts);

my $dir = dirname($0);
$| = 1;

my $msg = shift @ARGV || "$dir/msg_mp";

use FileHandle;
my $fh = new FileHandle $msg;

my $header;
my $boundary;
my $body;

while (<$fh>) {
    s/\r\n$/\n/;

    if (1 .. /^$/) {
	$header .= $_;
	if (/boundary\s*=\s*\"(.*)\"/i) {
	    $boundary = $1;
	}
    }
    else {
	$body .= $_; 
    }
}

my $original_length = length($body);

use Mail::Message;
my $m = new Mail::Message { 
    data_type   => 'multipart/mixed',
    boundary       => $boundary,
    data        => \$body,
    debug          => 1,
};

$m->print;

if ($opts{ d }) { debug( $m );}

exit 0;


sub debug
{
    my ($m) = @_;

    my $p;
    my $total=0;
    for ($p = $m; defined $p ; $p = $p->{ next }) {
	my $size = $p->size;
	my $h    = $p->get_data_header;
	$size   += length($h) if defined $h;
	
	$total += $size;
	print STDERR "type: ", $p->get_data_type, "\n";
	print STDERR " hdr:{", $h,                   "}\n";
	print STDERR "body:{", $p->get_data_body, "}\n";
	print STDERR "size: ", $size, " / $total (<= $original_length)\n";
	print STDERR "\n";
	sleep 3;
    }
}
