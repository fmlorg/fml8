#!/usr/bin/env perl
#
# $FML: message_id.pl,v 1.3 2001/08/05 13:09:00 fukachan Exp $
#

use strict;
use File::Basename;
use vars qw(%opts);
use lib qw(lib ../../cpan/lib);

test();

gen_message_id();

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
    $dir = $dir || "/tmp/fml5";
    -d $dir || system "mkdir /tmp/fml5";
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

sub gen_message_id
{
    print "\n* generate message_id\n";

    use FML::Header::MessageID;
    my $obj = new FML::Header::MessageID;

    my $curproc = { config => { address_for_post => 'elena@fml.org' }};
    my $args = {};

    print $obj->gen_id($curproc, $args), "\n";
    print $obj->gen_id($curproc, $args), "\n";
    print $obj->gen_id($curproc, $args), "\n";
}
