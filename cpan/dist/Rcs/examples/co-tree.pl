#!/usr/bin/perl -w

use strict;
use File::Find;
use File::Path;
use Rcs;

Rcs->bindir("/usr/bin");

my $lock = 0;

# Traverse desired filesystems

my $tree_root = '/home/freter/tmp';
my $rcs_path = '/RCS';
my $chkpt_path = '/chkpt';

find(\&wanted, $tree_root . $rcs_path);

exit;

sub wanted {
    my $relative_path = $File::Find::dir;
    ($relative_path) =~ s{^$tree_root$rcs_path}{};
    print $relative_path;
    print "\n";
    mkpath([$tree_root . $chkpt_path . $relative_path], 1, 0755);

    return unless -f;
    my $obj = Rcs->new;
    s/,v$//;
    $obj->file($_);
    $obj->rcsdir($tree_root . $rcs_path . $relative_path);
    $obj->workdir($tree_root . $chkpt_path . $relative_path);

    # check out and lock
    if ($lock) {
        $obj->co("-l");
    }

    # check out read only
    else {
        $obj->co;
    }
}
