use strict;
use File::Basename;
use vars qw(%opts);

use Getopt::Std;
getopts('d', \%opts);

my $dir = dirname($0);
$| = 1;

my $msg = shift @ARGV || "$dir/msg_mp";

use FileHandle;
my $fh = new FileHandle $msg;

my $header;
my $boundary;
my $content_type;
my $body;

while (<$fh>) {
    s/\r\n$/\n/;

    if (1 .. /^$/) {
	$header .= $_;
	if (/boundary=\"(.*)\"/) {
	    $boundary = $1;
	}
	if (/Content-Type: (\S+\/\S+\w)/) {
	    $content_type = $1;
	}
    }
    else {
	$body .= $_; 
    }
}

my $original_length = length($body);

use Mail::Message;
my $m = new Mail::Message { 
    content_type   => ($content_type || 'multipart/mixed'),
    boundary       => $boundary,
    content        => \$body,
    debug          => 1,
};

$m->print;
my $mp = $m->get_first_plaintext_message ;
print "// first plain/text message\n";
$mp->print;
print "//\n";
debug( $mp );

exit 0;


sub debug
{
    my ($m) = @_;

    unless (defined $m) {
	use Carp;
	croak("debug gets non-object\n");
    }

    my $p;
    my $total=0;
    my $i = 0;
    for ($p = $m; defined $p ; $p = $p->{ next }) {
	my $size = $p->size;
	my $h    = $p->get_content_header;
	$size   += length($h) if defined $h;

	$total += $size;

	$i++;
	print STDERR "--------- $i ---------\n"; 
	print STDERR "num_p:", $p->num_paragraph, "\n\n";
	next;

	print STDERR "type: ", $p->get_content_type, "\n";
	print STDERR " hdr:{", $h,                   "}\n";
	print STDERR "body:{", $p->get_content_body, "}\n";
	print STDERR "size: ", $size, " / $total (<= $original_length)\n";
	print STDERR "\n";
	sleep 3;
    }
}
