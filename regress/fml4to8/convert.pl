#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use vars qw($count %stab);

load_default();

for my $f (@ARGV) {
    my $s = gen_eval_string($f);
    eval $s;
    print "error: $@\n" if $@;
}

exit 0;


sub load_default
{
    package default;
    no strict;
    $DIR = '$DIR';
    require "/usr/local/fml/default_config.ph";
    package main;
}


sub gen_eval_string
{
    my ($f) = @_;
    my $s = '';

    $count++;

    $s  = "no strict;\n";
    $s .= sprintf("package config%03d;\n", $count);
    $s .= sprintf("\$DIR = \'\$DIR\';\n");
    $s .= sprintf("require \"%s\";\n", $f);
    $s .= sprintf("package main;\n");
    $s .= sprintf("*stab = *{\"config%03d::\"};\n", $count);
    $s .= "use strict;\n";
    $s .= sprintf("var_dump('config%03d', \\%%stab);\n", $count);

    return $s;
}

sub var_dump
{
    my ($package, $stab) = @_;
    my ($key, $val, $def, $x);

    # resolv
    eval "\$x = \$${package}::MAIL_LIST;\n";
    my ($ml_name, $ml_domain) = split(/\@/, $x);

    while (($key, $val) = each(%$stab)) {
	eval "\$val = \$${package}::$key;\n";
	eval "\$def = \$default::$key;\n";
	$val =~ s/$ml_name/\$ml_name/g;
	$val =~ s/$ml_domain/\$ml_domain/g;
	print "$key => $val\n" if $val && ($val ne $def);
    }
}
