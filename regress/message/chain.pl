#!/usr/pkg/bin/perl
#
# $FML: dump.pl,v 1.2 2001/09/23 12:18:16 fukachan Exp $
#

use lib qw(../../fml/lib ../../cpan/lib ../../im/lib);

use FileHandle;
use Mail::Message;

my $f   = shift @ARGV;
my $fp  = $ENV{METHOD} || "data_type";
my $fh  = new FileHandle $f;
my $wh  = new FileHandle "> $tmp";
my $obj = Mail::Message->parse( { fd => $fh } );

# all
{
    print "ALL\n";

    for (my $mp = $obj, my $i = 0; $mp ; $mp = $mp->{ next } ) {
	$i++;
	my $type = $mp->$fp();
	my $e    = $mp->encoding_mechanism();
	printf "object(%02d) type = %-25s %s\n", $i, $type, $mp;
    }
}

# head
{
    print "\n";
    print "HEAD (HEADER)\n";

    my $mp   = $obj;
    my $type = "unknown"; # $mp->$fp();
    my $e    = "unknown"; # $mp->encoding_mechanism();
    printf "object(%02d) type = %-25s %s\n", $i, $type, $mp;
}

# head
{
    print "\n";
    print "BODY HEAD\n";

    my $mp   = $obj->whole_message_body_head();
    my $type = $mp->$fp();
    my $e    = $mp->encoding_mechanism();
    printf "object(%02d) type = %-25s %s\n", $i, $type, $mp;
}

# tail
{
    print "\n";
    print "BODY TAIL\n";

    my $mp   = $obj->whole_message_body_tail();
    my $type = $mp->$fp();
    my $e    = $mp->encoding_mechanism();
    printf "object(%02d) type = %-25s %s\n", $i, $type, $mp;

    if ($ENV{DUMP}) {
	use Data::Dumper;
	print Dumper($mp);
    }
}

exit 0;
