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
my @m = ();

for $msg (@ARGV) {
    my $m = new MailingList::Messages { 
	content_type   => 'text/plain',
	charset        => 'iso-2022-jp',
	boundary       => $boundary,
	filename       => $msg,
	debug          => 1,
    };
    push(@m, $m);
}

$master = $m[0];
$master = $master->build_mime_multipart_chain( {
    base_content_type => 'multipart/mixed',
    message_list      => \@m,
});
$master->raw_print;

exit 0;
