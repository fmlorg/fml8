#!/usr/bin/perl -w

use strict;
use File::Find;
use File::Path;
use Rcs;

Rcs->bindir("/usr/bin");

my $comment = shift;

# Traverse desired filesystems

my $tree_root = '/home/freter/tmp';
my $rcs_path = '/RCS';
my $src_path = '/src';

find(\&wanted, $tree_root . $src_path);

exit;

sub wanted {
    my $relative_path = $File::Find::dir;
    ($relative_path) =~ s{^$tree_root$src_path}{};
    print $relative_path;
    print "\n";
    mkpath([$tree_root . $rcs_path . $relative_path], 1, 0755);

    return unless -f;
    my $obj = Rcs->new;
    $obj->file($_);
    $obj->rcsdir($tree_root . $rcs_path . $relative_path);
    $obj->workdir($tree_root . $src_path . $relative_path);

    # archive file exists
    if (! -e $obj->rcsdir . '/' . $obj->arcfile) {
        print "Initial Check-in\n";
        $obj->ci("-l", "-t-$comment");
    }

    # create archive file
    else {
        print "Check-in\n";
        $obj->ci("-l", "-m$comment");
    }
}
