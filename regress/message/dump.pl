#!/usr/pkg/bin/perl
#
# $FML: dump.pl,v 1.1 2001/09/23 11:23:38 fukachan Exp $
#

use lib qw(../../fml/lib ../../cpan/lib ../../im/lib);

use FileHandle;
use Mail::Message;

my $f   = shift @ARGV;
my $fh  = new FileHandle $f;
my $wh  = new FileHandle "> $tmp";
my $obj = Mail::Message->parse( { fd => $fh } );

use Data::Dumper;

print Dumper( $obj );

for (my $mp = $obj, my $i = 0; $mp ; $mp = $mp->{ next } ) {
    $i++;
    my $type = $mp->get_data_type();
    my $e    = $mp->get_encoding_mechanism();
    printf "object(%d) type = %-30s encoding= %-10s\n", $i, $type, $e;
}
