#!/usr/bin/env perl
#
# $FML: lock.pl,v 1.6 2002/04/18 14:18:07 fukachan Exp $
#

use strict;
my $debug = defined $ENV{'debug'} ? 1 : 0;

use File::SimpleLock;
my $lockobj = new File::SimpleLock;

print STDERR "File::SimpleLock ";

my $r = $lockobj->lock( { file => '/tmp/fml5' });
if ($r) { 
    print STDERR "lock ($$) ... ok\n";
}
else {
    print STDERR $lockobj->error, "\n";
}

sleep 1;

print STDERR "File::SimpleLock ";

$r = $lockobj->unlock( { file => '/tmp/fml5' });
if ($r) { 
    print STDERR "unlock ... ok\n";
}
else {
    print STDERR $lockobj->error, "\n";
}

exit 0;
