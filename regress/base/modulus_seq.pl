#!/usr/local/bin/perl
#
# $Id$
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
