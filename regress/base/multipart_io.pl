use strict;
use File::Basename;

my $dir = dirname($0);

$| = 1;

my $msg = "$dir/msg_mp";

use FileHandle;
my $fh = new FileHandle $msg;

my $header;
my $boundary;
my $body;

while (<$fh>) {
    if (1 .. /^$/) {
	$header .= $_;
	if (/boundary=\"(.*)\"/) {
	    $boundary = "--".$1;
	}
    }
    else {
	$body .= $_; 
    }
}

use MailingList::Messages;
my $m = new MailingList::Messages { 
    content_type   => 'multipart/mixed',
    boundary       => $boundary,
    content        => \$body,
    debug          => 1,
};

$m->print;

exit 0;
