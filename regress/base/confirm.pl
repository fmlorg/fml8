#!/usr/bin/env perl
#
# $FML: confirm.pl,v 1.1 2001/10/13 03:17:25 fukachan Exp $
#

use strict;
use lib qw(../../fml/lib ../../cpan/lib);
use FML::Confirm;

my $debug   = defined $ENV{'debug'} ? 1 : 0;
my $confirm = new FML::Confirm {
    cache_dir => "/tmp/confirm.cache",
    class     => "subscribe",
    address   => "fukachan\@fml.org",
    buffer    => "subscribe kenichi fukamachi",
};

print "id = ", $confirm->assign_id(), "\n";

exit 0;
