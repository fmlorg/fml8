#!/usr/local/bin/perl
#
# $FML$
#

use strict;
use File::Basename;
use vars qw(%opts);
use lib qw(lib ../../cpan/lib);

test();

for my $msg (@ARGV) {
    message_io_test($msg);
}

exit 0;


sub test
{
    print "\n* IO test of FML::Header::MessageID module\n";

    use FML::Header::MessageID;
    my $obj = new FML::Header::MessageID;

    my $dir;
    chop($dir = `mktemp -d -t /tmp`);
    $dir = $dir || "/tmp/a";
    -d $dir || system "mkdir /tmp/a";
    $obj->open_cache( { directory => $dir } );

    my $key = time . "-$$";

    for (1 .. 10) {
	$obj->set( "$key.$_" , time );
    }

    print $obj->get( "$key.3" ), "\n";
}


sub message_io_test
{
    my ($msg) = @_;

    print "\n* extract message_id from $msg\n";

    use FileHandle;
    my $fd = new FileHandle $msg;

    use Mail::Message;
    my $msg = Mail::Message->parse( {
	fd           => $fd,
	header_class => 'FML::Header',
    });

    my $header = $msg->rfc822_message_header;
    my $h      = $header->extract_message_id_references();
    for (@$h) { print $_, "\n";}
}
