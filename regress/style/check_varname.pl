#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

$| = 1;

my $debug = 0;

my $varname;
my %varname;
my %base;

while (<>) {
    next if /^\#/;

    if (/^[a-z].*=/) {
	($varname) = split(/\s*=\s*/, $_);
	$varname{ $varname } = $varname;
    }
}


base();
global();
inherit();

first_match('path');
first_match('has');
first_match('cgi');
first_match('fml');
first_match('domain');
first_match('sql');
first_match('ldap');
first_match('commands_for');
first_match('default');
first_match('smtp');
first_match('mail');
first_match('postfix');
first_match('qmail');
first_match('sendmail');
first_match('procmail');

last_match('dir');
last_match('sequence_file');
last_match('file');
last_match('mode');
last_match('charset');

misc();


exit 0;


sub base
{
    for my $varname (sort keys %varname) {
	print $varname, "\n" if $debug && ($varname =~ /incoming/);

	if ($varname =~ /^use_(\S+)_program/) {
	    $base{ $1 } = $1;
	    print "1. \$base{ $1 } = $1;\n" if $debug;
	}
	elsif ($varname =~ /^use_([a-z_]+)/) {
	    $base{ $1 } = $1;
	    print "2. \$base{ $1 } = $1;\n" if $debug;
	}
	elsif ($varname =~ /(\S+_restrictions)$/) {
	    $base{ $1 } = $1;
	}
	elsif ($varname =~ 
	       /^(incoming_command_mail|outgoing_command_mail)_\S+/) {
	    $base{ $1 } = $1;
	}
	elsif ($varname =~ /^(incoming_article|outgoing_article)_\S+/) {
	    $base{ $1 } = $1;
	}
	elsif ($varname =~ /^(\w+_command)_\S+/) {
	    $base{ $1 } = $1;
	}
    }

    for my $varname (sort _longest keys %varname) {
	if ($varname =~ /^(\S+_password)_maps/) {
	    $base{ $1 } = $1;
	    next;
	}

	if ($varname =~ /^(\S+)_maps/) {
	    $base{ $1 } = $1;
	}
    }
}


sub _longest
{
    my $xa = length($a);
    my $xb = length($b);

    $xb <=> $xa;
}


sub global
{
    print "__global__ {\n";
    for my $x (qw(maintainer timezone system_accounts)) {
	_print($x);
	delete $varname{ $x };
    }
    print "}\n";
}


sub inherit
{
    my %b = ();

    for my $base (sort _longest keys %base) {
	my @x = ();
	my $pat1 = sprintf("%s_%s", '\S+', $base);
	my $pat2 = sprintf("%s_%s", $base, '\S+');

	for my $varname (sort keys %varname) {
	    if ($varname =~ /^$base$|^$pat1|^$pat2/) {
		push(@x, $varname);
		delete $varname{ $varname };
	    }
	}

	$b{ $base } = \@x;
    }

    for my $base (sort keys %b) {
	print "\n$base { \n";

	my $x = $b{ $base };
	for my $varname (@$x) {
	    _print($varname);
	}

	print "}\n";
    }
}


sub first_match
{
    my ($x) = @_;
    my $pat = sprintf("%s_", $x);

    print "\n^$pat {\n";
    for my $varname (sort keys %varname) {
	if ($varname =~ /^$pat/) {
	    _print($varname);
	    delete $varname{ $varname };
	}
    }
    print "}\n";
}


sub last_match
{
    my ($x) = @_;
    my $pat = sprintf("_%s", $x);

    print "\n$pat\$ {\n";
    for my $varname (sort keys %varname) {
	if ($varname =~ /$pat$/) {
	    _print($varname);
	    delete $varname{ $varname };
	}
    }
    print "}\n";
}


sub misc
{
    print "\n// misc\n";

    for my $varname (sort keys %varname) {
	_print($varname);	
    }
}



sub _print
{
    my ($x) = @_;

    if (_match($x)) {
	printf "%8s  %s\n", "", $x;
    }
    else {
	printf "%8s  %s\n", "   ?   ", $x;
    }
}


sub _match
{
    my ($x) = @_;

    if ($x =~ /^use_|^path_|^has_/) {
	return 1;
    }
    elsif ($x =~ /_file$|_dir$|_files$|_dirs$|_size_limit$|_maps$|_rules$|_type$|^primary_\S+_map$|_restrictions$|_functions$/) {
	return 1;
    }
    else {
	return 0;
    }
}
