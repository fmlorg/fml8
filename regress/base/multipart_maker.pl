#!/usr/local/bin/perl

use strict;
use File::Basename;
use MailingList::Messages;
use Getopt::Std;

my %opts;

getopts('mr:', \%opts);

my $rcpt = $opts{ r } || undef; 

my $dir = dirname($0);

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
	$args->{ content_type } = 'message/rfc822';
    }
    # text 
    else {
	$args->{ content_type } = 'text/plain';
	$args->{ charset      } = 'iso-2022-jp';
    }

    my $m = new MailingList::Messages $args;
    push(@m, $m);
}

$master = $m[0];
$master = $master->build_mime_multipart_chain( {
    base_content_type => 'multipart/mixed',
    boundary          => $boundary,
    message_list      => \@m,
});


if ($rcpt) {
    print "From: $rcpt\n";
    print "To: $rcpt\n";
    print "MIME-version: 1.0\n";
    print "Content-Type: multipart/mixed;\n";
    print "  boundary=\"$boundary\"\n";
    print "\n";
}

$master->raw_print;

exit 0;
