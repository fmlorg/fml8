#!/usr/local/bin/perl
#
# $FML: modulus_seq.pl,v 1.1 2001/02/21 03:41:18 fukachan Exp $
#

$seq_file = "/tmp/.seq";

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
