#!/usr/local/bin/perl
#
# $Id$
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
