#!/usr/local/bin/perl
#
# $FML: lock.pl,v 1.4 2001/06/17 09:00:30 fukachan Exp $
#

use File::SimpleLock;
my $lockobj = new File::SimpleLock;

my $r = $lockobj->lock( { file => '/tmp/fml5' });
if ($r) { 
    print STDERR "lock ($$) ... ok\n";
}
else {
    print STDERR $lockobj->error, "\n";
}

sleep 1;

$r = $lockobj->unlock( { file => '/tmp/fml5' });
if ($r) { 
    print STDERR "unlock ... ok\n";
}
else {
    print STDERR $lockobj->error, "\n";
}

exit 0;
