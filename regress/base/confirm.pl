#!/usr/bin/env perl
#
# $FML$
#

use lib qw(../../fml/lib ../../cpan/lib);
use FML::Confirm;

my $confirm = new FML::Confirm {
    cache_dir => "/tmp/confirm.cache",
    class     => "subscribe",
    address   => "fukachan\@fml.org",
    buffer    => "subscribe kenichi fukamachi",
};

print "id = ", $confirm->assign_id(), "\n";

exit 0;
