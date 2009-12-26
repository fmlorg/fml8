#!/usr/bin/env perl
#
# THE CHARSET OF THIS FILE is EUC-JP.
#
# $FML$
#

use strict;
use Carp;
use File::Basename;
use File::Spec;

my $base_dir = sprintf("%s/../../../", dirname($0));
my $changes  = File::Spec->catfile($base_dir, "CHANGES.txt");
unless (-f $changes) {
    croak("cannot find $changes\n");
}

my $fml_version          = get_version($changes);
my $date                 = get_date();
my $fml_version_comment  = sprintf("(バージョン %s-%s)", $fml_version, $date);
my $sgml_version_comment = quotemeta("<!-- __FML_CURRENT_VERSION__ -->");

while (<>) {
    if (/^(.*)$sgml_version_comment/) {
	my ($prefix) = ($1);
	print $prefix, $fml_version_comment, "\n";
	print "\t<!-- FML_CURRENT_VERSION=\"$fml_version_comment\" -->\n"; 
    }
    else {
	print;
    }
}

exit 0;

sub get_version
{
    my ($file) = @_;
    my $version = undef;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my $buf;

      LINE:
	while ($buf = <$rh>) {
	    if ($buf =~ /FML_CURRENT_VERSION=(\S+)/) {
		$version = $1;
		$version =~ s/\s*$//;
		last LINE;
	    }
	}
	$rh->close();
    }

    return $version;
}


sub get_date
{
    my ($time) = @_;

    $time ||= time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = (localtime($time))[0..6];
    return sprintf("%04d%02d%02d", 1900 + $year, $mon + 1, $mday);
}
