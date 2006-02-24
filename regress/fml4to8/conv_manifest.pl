#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

my $manifest = shift || "../../gnu/dist/fml4/cf/MANIFEST";
my $time     = time;
my $base_dir = "/work/tmp/fml4to8.$time.$$";

conv_manifest($manifest);

exit 0;


sub conv_manifest
{
    my ($manifest) = @_;

    use FileHandle;
    my $rh = new FileHandle $manifest;
    if (defined $rh) {
	my $current_value;
	my $buf;

      LINE:
	while ($buf = <$rh>) {
	    last LINE if $buf =~ /^LOCAL_CONFIG/;

	    chomp $buf;

	    if ($buf =~ /value:\s*(.*)$/) {
		$current_value = $1;
		$current_value =~ s/^\s*//;
		$current_value =~ s/\s*$//;
	    }
	    elsif ($buf =~ /^([A-Z]\S+):\s*(.*)/) {
		_print($1, $2, $current_value);
	    }
	}

	$rh->close();
    }
}


sub _print
{
    my ($name, $value, $select) = @_;

    if (0) {
	printf "# %-30s = %-10s [%s]\n", $name, $value, $select;
    }

    if ($select =~ /string/) {
	printf "%-30s = %-10s\n", $name, $value;
    }
    elsif ($select =~ /^\s*address\s*$/) {
	printf "%-30s = %-10s\n", $name, "rudo\@nuinui.net";
    }
    elsif ($select =~ /^\s*number\s*$/) {
	printf "%-30s = %-10s\n", $name, "0 | 1 | 987654321";
    }
    elsif ($select =~ /^\s*string\s*$/) {
	printf "%-30s = %-10s\n", $name, "\"\" | __STRING__";
    }
    elsif ($select =~ /^\s*strings\s*$/) {
	printf "%-30s = %-10s\n", $name, "\"\" | __STRING__";
    }
    else { 
	$select =~ s/\s*\/\s*/ \| /g;
	printf "%-30s = %-10s\n", $name, $select;
    }
}
