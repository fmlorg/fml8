#!/usr/bin/env perl
#
# $FML: multipart_maker.pl,v 1.9 2001/05/06 08:25:02 fukachan Exp $
#

use strict;
use File::Basename;
use Mail::Message;
use Getopt::Std;

my $debug = defined $ENV{'debug'} ? 1 : 0;

my %opts;
getopts('mr:', \%opts);

my $rcpt = $opts{ r } || undef; 
my $dir  = dirname($0);

$| = 1;

my $header;
my $boundary = "--". time;
my $body;
my $m_prev;
my $msg;
my $master;
my @m = ();

for $msg (@ARGV) {
    my $args = { 
	boundary       => $boundary,
	filename       => $msg,
	debug          => 1,
    };

    # mail ?
    if ($opts{ m }) {
	$args->{ data_type } = 'message/rfc822';
    }
    # text 
    else {
	$args->{ data_type } = 'text/plain';
	$args->{ charset   } = 'iso-2022-jp';
    }

    my $m = new Mail::Message $args;
    push(@m, $m);
}

$master = $m[0];
$master = $master->build_mime_multipart_chain( {
    base_data_type => 'multipart/mixed',
    boundary       => $boundary,
    message_list   => \@m,
});


if ($rcpt) {
    print "From: $rcpt\n";
    print "To: $rcpt\n";
    print "MIME-version: 1.0\n";
    print "Content-Type: multipart/mixed;\n";
    print "  boundary=\"$boundary\"\n";
    print "\n";
}

$master->print;

exit 0;
