#!/usr/local/bin/perl
#
# $FML: lock.pl,v 1.3 2001/02/20 08:30:12 fukachan Exp $
#

use File::SimpleLock;
my $lockobj = new File::SimpleLock;

my $r = $lockobj->lock( { file => '/tmp/a' });
if ($r) { 
    print STDERR "lock ($$) ... ok\n";
}
else {
    print STDERR $lockobj->error, "\n";
}

sleep 1;

$r = $lockobj->unlock( { file => '/tmp/a' });
if ($r) { 
    print STDERR "unlock ... ok\n";
}
else {
    print STDERR $lockobj->error, "\n";
}

exit 0;
