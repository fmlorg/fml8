#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

my $p = {};

for my $lang (qw(ja en)) {
    $p->{ $lang } = read_cf_in_dir($lang, "etc/src/config.cf.$lang");
}

var_compare("ja", "en", $p->{ ja }, $p->{ en } );
var_compare("en", "ja", $p->{ en }, $p->{ ja } );

exit 0;


sub read_cf_in_dir
{
    my ($lang, $dir) = @_;
    my $hash = {};

    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my $x;

      ENTRY:
	while ($x = $dh->read()) {
	    next ENTRY if $x =~ /^\./;
	    next ENTRY if $x =~ /^CVS/;
	    next ENTRY if $x !~ /\.cf$/;

	    use File::Spec;
	    my $f = File::Spec->catfile($dir, $x);
	    read_cf($hash, $f);
	}
    }

    return $hash;
}


sub read_cf
{
    my ($x, $f) = @_;

    use FileHandle;
    my $fh = new FileHandle $f;
    if (defined $fh) {
	my $buf;

	while ($buf = <$fh>) {
	    if ($buf =~ /^([\w\d_]+).*=/) {
		$x->{ $1 } = 1;
	    }
	}
	$fh->close();
    }
}


sub var_compare
{
    my ($tablename_x, $tablename_y, $x, $y) = @_;

    for my $k (keys %$x) {
	unless ($y->{ $k }) {
	    printf "%-5s %s\n", $tablename_y, "no $k";
	}
    }
}
