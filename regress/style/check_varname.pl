#!/usr/bin/env perl
#
# $FML: check_varname.pl,v 1.1 2003/05/29 13:38:17 fukachan Exp $
#

use strict;
use Carp;
use vars qw(@exceptional $debug $varname %varname %base %done %top);

init();
parse();
base();
exceptional();
inherit();

last_match('file');
last_match('dir');

unclassified();

exit 0;


sub init
{
    $|     = 1;
    $debug = 0;

    # exceptional category
    @exceptional = qw(timezone);

    # top level category
    for (qw(path directory system has
	    default domain 
	    cgi commands_for 
	    sql ldap
	    smtp mail postfix qmail sendmail procmail)) {

	$top{ $_ } = $_;
    }
}


sub parse
{
    while (<>) {
	next if /^\#/o;

	if (/^[a-z].*=/o) {
	    ($varname) = split(/\s*=\s*/, $_);
	    $varname{ $varname } = $varname;
	}
    }
}


sub regist
{
    my ($x) = @_;
    my $s = (split(/_/, $x))[0];

    $top{ $s }  = $s;
    $base{ $x } = $x;

    return $x;
}


sub base
{
    for my $varname (sort keys %varname) {
	if ($varname =~ /^use_(\S+)_program/) {
	    regist($1);
	}
	elsif ($varname =~ /^use_([a-z_]+)/) {
	    regist($1);
	}
	elsif ($varname =~ /(\S+_restrictions)$/) {
	    regist($1);
	}
	elsif ($varname =~ 
	       /^(incoming_command_mail|outgoing_command_mail)_\S+/) {
	    regist($1);
	}
	elsif ($varname =~ /^(incoming_article|outgoing_article)_\S+/) {
	    regist($1);
	}
	elsif ($varname =~ /^(\w+_command)_\S+/) {
	    regist($1);
	}
    }

    for my $varname (sort _longest keys %varname) {
	if ($varname =~ /^(\S+_password)_maps/) {
	    regist($1);
	    next;
	}

	if ($varname =~ /^(\S+)_maps/) {
	    regist($1);
	}
    }
}


sub _longest
{
    my $xa = length($a);
    my $xb = length($b);

    $xb <=> $xa;
}


sub exceptional
{
    if (@exceptional) {
	print "__exceptional__ {\n";
	for my $x (@exceptional) {
	    _print($x);
	    delete $varname{ $x };
	}
	print "}\n\n";
    }
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

    for my $top (sort keys %top) {
	print "$top {\n";

	for my $base (sort keys %b) {
	    if ($base =~ /^$top/) {
		print "\n"; 
		print "   ";
		print "$base { \n";

		my $x = $b{ $base };
		for my $varname (@$x) {
		    _print($varname);
		}

		print "   ";
		print "}\n";
	    }
	}

	__print_if_match($top);

	print "}\n";
	print "\n"; 
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


sub unclassified
{
    print "\n\n*** unclassified ***\n";

    for my $varname (sort keys %varname) {
	_print($varname);	
    }
}


sub __print_if_match
{
    my ($top) = @_;
    my @x = ();

    for my $varname (sort keys %varname) {
	next if $done{ $varname };
	push(@x, $varname) if $varname =~ /^${top}_/;
	push(@x, $varname) if $varname =~ /^${top}$/;
    }

    if (@x) {
	print "\n";
	print "   ", $top , "_* {\n";
	for my $varname (@x) {
	    _print($varname);
	}
	print "   }\n";
    }
}


sub _print
{
    my ($x) = @_;

    return if $done{ $x };
    $done{ $x } = 1;

    if (_match($x)) {
	printf "%8s  \$%s\n", "", $x;
    }
    else {
	printf "%8s  \$%s\n", "   ?   ", $x;
    }
}


sub _match
{
    my ($x) = @_;
    my $pat;

    # pattern to permit at the last of name.
    my @pat = qw(file dir type format format_type files dirs
		 size_limit map maps rules type restrictions
		 functions);

    for (@pat) { 
	$pat .= $pat ? "|" : ''; 
	$pat .= sprintf("_%s\$", $_);
    }

    if ($x =~ /^use_|^path_|^has_/) {
	return 1;
    }
    elsif ($x =~ /$pat/) {
	return 1;
    }
    else {
	return 0;
    }
}
