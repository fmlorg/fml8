#!/usr/bin/env perl
#
# $FML: modulus_seq.pl,v 1.2 2001/06/17 09:00:30 fukachan Exp $
#

use strict;
my $debug    = defined $ENV{'debug'} ? 1 : 0;
my $seq_file = "/tmp/.seq";

for ( 1 .. 10 ) {
    &id;
}

exit 0;

sub id
{
    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file , modulus => 3};
    my $id  = $sfh->increment_id;
    print $id, "\n";
}
