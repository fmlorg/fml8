#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);

for my $f (@ARGV) {
    use File::Basename;
    my $dir = dirname($f);
    my $fn  = basename($f);

    print STDERR "Log> process $fn\n";

    my $args = {
	fd          => \*STDOUT,
	db_base_dir => "/var/spool/ml/\@db\@/thread",
	ml_name     => 'elena',
	spool_dir   => $dir,
	article_id  => $fn,
    };

    use Mail::Message;
    my $fh  = new FileHandle $f;
    my $msg = Mail::Message->parse({ fd => $fh });

    use Mail::ThreadTrack;
    my $ticket = new Mail::ThreadTrack $args;
    $ticket->analyze($msg);

    $ticket->show_summary();
}
