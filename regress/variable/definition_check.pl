#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use File::Basename;
use File::Spec;

my $eval;
my $value;
my $base_dir        = dirname($0);
my $definition_file = File::Spec->catfile($base_dir, "list.value");
my %val = ();

_init();

while (<>) {
    if (/^\s*$/) {
	$value = '';
    }

    if (/Value:\s+(\S+)/) {
	$value = $1;
    }

    if (/^([_a-z]+)\s+=/) {
	$val{ $1 } = $value; 
    }
}

my $i = 0;
for my $k (sort keys %val) {
    if (! _valid($k, $val{$k})) {
	# printf "%-30s => %s\n", $k, $val{$k};
	printf "%s\t%s\n", $k, $val{$k};
	$i++;
    }
}

print "\n$i left.\n\n";

exit 0;


sub _init
{
    use FileHandle;
    my $rh = new FileHandle $definition_file;
    if (defined $rh) {
	while (<$rh>) {
	    next if /^\#/;
	    my ($k, $v) = split(/\s+/, $_);
	    if ($k && $v) {
		$eval .= "if (\$k =~ /$k/ && \$v eq '$v') { \$r = 1;};\n";
	    }
	}
    }
    else {
	croak("cannot open $definition_file\n");
    }
}


sub _valid
{
    my ($k, $v) = @_;
    my $r = 0;

    eval $eval;
    croak($@) if $@;

    return $r;
}
