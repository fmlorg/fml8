use strict;
use File::Basename;

my $dir = dirname($0);

$| = 1;

my $msg = shift || "/etc/fml/main.cf";

use FileHandle;
my $fh = new FileHandle $msg;

my $header;
my $boundary;
my $body;

use MailingList::Messages;
my $m = new MailingList::Messages { 
    content_type   => 'text/plain',
    charset        => 'iso-2022-jp',
    boundary       => $boundary,
    filename       => $msg,
    debug          => 1,
};

$m->raw_print;

exit 0;
