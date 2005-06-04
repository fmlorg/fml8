#!/usr/bin/env perl
#
# $FML: varclass.pl,v 1.5 2003/11/15 02:52:04 fukachan Exp $
# based on 'FML: check_varname.pl,v 1.3 2003/05/30 13:59:17 fukachan Exp'
#

use strict;
use Carp;
use vars qw(@exceptional $debug $varname %varname %base %done %top);

my %option = ();
use Getopt::Long;
GetOptions(\%option, qw(debug! d! sgml! html!));

init();
parse();
find_base();

print_sgml_pre() if $option{ sgml };

# print
{
    exceptional();
    classfied();
    suffix('file');
    suffix('dir');
    unclassified();
}

print_sgml_post() if $option{ sgml };

exit 0;


sub init
{
    $|     = 1;
    $debug = 0;

    # exceptional category
    @exceptional = qw(timezone);

    # top level category
    for (qw(path directory system
	    default
	    domain 
	    cgi 
	    sql
	    ldap
	    message
	    reply_message
	    report_mail
	    template_file
	    ml_local
	    x
	    post
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


sub _regist
{
    my ($x) = @_;
    my $s = (split(/_/, $x))[0];

    if ($x =~ /^[a-zA-Z0-9]+_command$/) {
	$top{ $x } = $x;
    }
    else {
	$top{ $s }  = $s;
    }

    $base{ $x } = $x;

    return $x;
}


sub find_base
{
    for my $varname (sort keys %varname) {
	if ($varname =~ /^use_(\S+)_program/) {
	    _regist($1);
	}
	elsif ($varname =~ /^use_(\S+)_function/) {
	    _regist($1);
	}
	elsif ($varname =~ /^use_([a-z_]+)/) {
	    _regist($1);
	}
	elsif (0 && $varname =~ /(\S+_address)$/) {
	    _regist($1);
	}
	elsif (0 && $varname =~ /(\S+_restrictions)$/) {
	    _regist($1);
	}
	elsif ($varname =~ 
	       /^(incoming_command_mail|outgoing_command_mail)_\S+/) {
	    _regist($1);
	}
	elsif ($varname =~ 
	       /^(fetchfml_article_post|fetchfml_command_mail|fetchfml_error_mail_analyzer)_\S+/) {
	    _regist($1);
	}
	elsif ($varname =~ /^(incoming_article|outgoing_article)_\S+/) {
	    _regist($1);
	}
	elsif ($varname =~ /^(\w+_command)_\S+/) {
	    _regist($1);
	}
    }

    for my $varname (sort _longest keys %varname) {
	if ($varname =~ /^(\S+_password)_maps/) {
	    _regist($1);
	    next;
	}

	if ($varname =~ /^(\S+)_maps/) {
	    _regist($1);
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


sub classfied
{
    my %b = ();

    for my $base (sort _longest keys %base) {
	my @x = ();
	my @y = ();
	my $pat1 = sprintf("%s_%s", '\S+', $base);
	my $pat2 = sprintf("%s_%s", $base, '\S+');

	for my $varname (sort keys %varname) {
	    if ($varname =~ /^$base$|^$pat1|^$pat2/) {
		push(@x, $varname);
		delete $varname{ $varname };
	    }
	}

	for my $x (@x) {
	    my $k = "default_$x";
	    if (defined $varname{ $k }) {
		push(@y, $k);
		print STDERR "push(\@y, $k);\n"; sleep 3;
		delete $varname{ $k };
	    }
	}

	push(@x, @y);
	$b{ $base }  = \@x;
    }

    for my $top (sort _sort_top keys %top) {
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


sub _sort_top
{
   my $xa = $a;
   my $xb = $b;

   if ($xa =~ /_command$/) { $xa = "command_$xa";}
   if ($xb =~ /_command$/) { $xb = "command_$xb";}

   $xa cmp $xb;
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


sub suffix
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
		 size_limit limit map maps rules type restrictions
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


sub print_sgml_pre
{
	print "<para>\n";
	print "<screen>\n";
}


sub print_sgml_post
{
	print "</screen>\n";
	print "</para>\n";
}
