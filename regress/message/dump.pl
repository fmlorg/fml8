#!/usr/pkg/bin/perl
#
# $FML$
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
