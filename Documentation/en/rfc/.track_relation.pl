#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.1 2001/08/07 12:23:48 fukachan Exp $
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;

# %rfc         rfc => rfc description
# %rfc_exists  rfc in this directory
# %rfc_prev    double link list
# %rfc_next    double link list 
my (%rfc_exists, %rfc, %rfc_prev, %rfc_next);
my ($r);

check_rfc_here();
read_rfc_index(); # set up %rfc
analyze( $r );
show( $r );


sub check_rfc_here
{
    for (<rfc*txt>) {
	if (/RFC(\d+)/i) {
	    my $x = sprintf("RFC%04d", $1);
	    $rfc_exists{$x} = $x;
	}
    }
}


sub read_rfc_index
{
    use FileHandle;
    my $fh  = new FileHandle "rfc-index.txt";
    my $cur = undef;

    if (defined $fh) {
	while (<$fh>) {
	    if (/^(\d+)/) {
		$cur = $1;
	    }

	    if (defined $cur) {
		$rfc{ "RFC$cur" } .= $_;
	    }
	}
	close($fh);
    }
}


sub analyze
{
    my ($rfc_link) = @_;

    # check link list for specified $rfc.
    # result: $rfc_prev{$rfc} <- $rfc -> $rfc_next{$rfc}
    for my $rfc (sort {$a<=>$b} keys %rfc_exists) {
	_analyze_links($rfc, $rfc{$rfc});
    }

    # combine link lists.
    my $r = {};
    _combine( $r );

    # o.k. summalize information as a link to the last component.
    #      
    #     A -> B -> LAST
    #     C -> D -> LAST
    #  =>
    #     A -> B -> C -> D -> LAST
    #      
    # This logic is incomplete, we chck all relation for all components.
    #      
    my ($k, $v);
    while (($k, $v) = each %$r) {
	my $last = _last_rfc($v);
	print "$k => @$v (last=$last)\n" if $debug;
	$rfc_link->{ $last } .= " ".join(" ", @$v );
    }
}


sub _last_rfc
{
    my ($ra) = @_;
    my (@rev) = reverse @$ra;
    return $rev[0];
}


sub _combine
{
    my ($result_link) = @_;

    for my $rfc (sort {$a<=>$b} keys %rfc_exists) {
	my (@linklist);
	my (@buf) = split(/\s+/, join(" ", 
				      $rfc_prev{ $rfc }, 
				      $rfc, 
				      $rfc_next{ $rfc }));

	for my $rfc (@buf) {
	    if (defined $rfc_prev{$rfc}) {
		push(@linklist, split(/\s+/, $rfc_prev{$rfc}));
	    }

	    push(@linklist, $rfc);
	}

	my $x = _remove_dup( \@linklist );
	$result_link->{ $rfc } = _remove_dup( \@linklist );
    }
}


sub _sort_links
{
    my ($a, $b) = @_;
    $a =~ /RFC/;
    $b =~ /RFC/;

    $a <=> $b;
}


sub _remove_dup
{
    my ($ra) = @_;
    my (%uniq);
    my (@rbuf);

    for (@$ra) {
	next if $uniq{$_};
	$uniq{$_} = 1;
	push(@rbuf, $_);
    }

    return \@rbuf;
}


sub _analyze_links
{
    my ($rfc, $s) = @_;

    # one line
    $s =~ s/\n/ /g;

    # Title of RFC.  Author 1, Author 2, Author 3.  Issue date.
    # (Format: ASCII) (Obsoletes xxx) (Obsoleted by xxx) (Updates xxx)
    # (Updated by xxx) (Also FYI ####) (Status: ssssss)

    if ($s =~ /(Obsoletes|Updates)([\s\w\d,]+)/i) {
	$rfc_prev{ $rfc } = _clean_up($2);
	_check_exists($rfc_prev{ $rfc } );
    }
    
    if ($s =~ /(Updated\s+by|Obsoleted\s+by)([\s\w\d,]+)/i) {
	$rfc_next{ $rfc } = _clean_up($2);
	_check_exists($rfc_next{ $rfc } );
    }
}


sub _check_exists
{
    my ($buf) = @_;

    for (split(/\s+/, $buf)) {
	if (/rfc\d+/i) {
	    my $fn = $_;
	    $fn =~ s/RFC/rfc/;
	    $fn =~ s/0(\d{3})/$1/;
	    $fn .= ".txt";
	    unless (-f $fn) {
		print "no $fn\n";
		if (-d "source") {
		    system "cp source/$fn.gz .";
		    system "gunzip *gz";
		}
	    }
	}
    }
}


sub _clean_up
{
    my ($s) = @_;

    $s =~ s/\n/ /g;
    $s =~ s/,/ /g;
    $s =~ s/^\s+//g;

    return $s;
}


sub show
{
    my ($r) = @_;

    my ($k, $v);
    while (($k, $v) = each %$r) {
	my @r  = split(/\s+/, $v);
	my $rv = _remove_dup( \@r );
	print "$k => @$rv\n";
    }


}

1;
