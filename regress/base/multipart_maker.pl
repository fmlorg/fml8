use strict;
use File::Basename;
use MailingList::Messages;

my $dir = dirname($0);

$| = 1;

my $header;
my $boundary;
my $body;
my $m_prev;
my $msg;
my $master;

for $msg (@ARGV) {
    my $m = new MailingList::Messages { 
	content_type   => 'text/plain',
	charset        => 'iso-2022-jp',
	boundary       => $boundary,
	filename       => $msg,
	debug          => 1,
    };

    $m_prev->next_chain( $m ) if defined $m_prev;
    $m_prev = $m;
    $master = $m unless $master; 
}

$master->raw_print;

exit 0;
