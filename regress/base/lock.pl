#!/usr/bin/env perl
#
# $FML: lock.pl,v 1.5 2001/08/05 13:09:00 fukachan Exp $
#

use strict;
my $debug = defined $ENV{'debug'} ? 1 : 0;

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
