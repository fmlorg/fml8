#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: find_bad_style.pl,v 1.9 2004/03/12 12:16:35 fukachan Exp $
#

use strict;
use Carp;
use File::stat;

my $in_sub    = 0;
my $in_head   = 0;
my $defined   = 0;
my $ioadapter = 0; 
my $mdqueue   = 0;
my $close     = 0;
my $count     = 0;
my $copyright = '';
my $buf       = '';
my $prev_argv = '';
my $prev_line = '';
my $comment   = '';
my $reason    = '';
my $fnf_args  = '';
my $cur_fn    = '';
my $implicit  = ();
my $cur_buf   = '';

while (<>) {
    $cur_buf = $_;

    if (/^\#.*(Copyright.*)/i) {
	$copyright = $1;
    }

    if (/^\#.*\$FML:.*(\d{4})\/\d{2}\/\d{2} /i) {
	my $year = $1;
	print "\n$ARGV\n\twrong copyright\n" unless $copyright =~ /$year/;

	# compare mtime
	if (0) {
	    my $st = stat($ARGV);
	    my $mt = $st->mtime;
	    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime($mt);
	    $year += 1900;
	    print "\n$ARGV\n\twrong copyright\n" unless $copyright =~ /$year/;
	}
    }

    # reset the line number counter
    if ($prev_argv ne $ARGV) {
	_info($prev_argv);
	$count     = 0;
	$prev_argv = $ARGV;
    }
    $count++;

    # holds comment buf;
    $comment .= $_ if /^\#/;

    if (/^\s*\#/ || /^\s*$/) {
	$prev_line = $_;
	next;
    }

    # ignore documents
    if (/^\=\w+/) {
	$prev_line = $_;
	$in_head   = 1;
	$in_head   = 0 if /^\=cut/;
	next;
    }
    if ($in_head) {
	$prev_line = $_;
	next;
    }

    # 
    # 1. check the usage of open() and close() under not check of defined()
    # 
    if (/IO::Adapter/) { $ioadapter = 1;};
    if (/Mail::Delivery::Queue/) { $mdqueue = 1;}
    if (/defined/) { $defined = 1;}
    if (/\$\S+\-\>(close|open)\(/ && (!/^sub /) && (!/^=head/) && (!/\$self/)) {
	unless ($defined || $ioadapter || $mdqueue) {
	    $buf .= " ===> ". $_;
	    $buf =~ s/\n/\n\t/gm;
	    $buf =~ s/^/\t/;
	    print "\n$ARGV $count {\n\tdefined() ?\n\n", $buf, "\n}\n\n";
	}
    }


    # 
    # 2. check FNF
    # 
    if (/^sub /) {
	unless ( _is_fnf($comment) ) {
	    print "\n$ARGV $count\n   $_\twrong FNF ($reason)\n";
	}
	undef $comment;
    }

    if ($in_sub && /^    my.*\@_;\s*$/) {
	_check_args( $ARGV, $_ );
    }
    $fnf_args = '' if /^\}/;
    $fnf_args = '' if /^sub .*\}/;


    # 
    # 3. usage of $_ is wrong.
    # 
    if ($in_sub) {
	local($_) = $cur_buf;
	$_ =~ s@/[\w/]+/@//@g;

	if (/\$_/o && (! /\$_[a-zA-Z0-9]\w+/)) {
	    _log('use_underbar', $ARGV, $cur_buf);
	}
	if (/if\s+.*\/|if.*m\W/o && (! /\$.*[=!]\~/o) && /\/\S+\//o) {
	    _log('use_underbar', $ARGV, $cur_buf);
	}

	if (/if\(/) {
	    _log('if_style', $ARGV, $cur_buf);
	}

	if (/for\(/) {
	    _log('for_style', $ARGV, $cur_buf);
	}
    }


    # 
    # last resort: logging buffer
    # 
    if (/^sub (\S+)|^\}/) {
	undef $buf;
	$cur_fn    = $1 . "()";
	$in_sub    = 1;
	$defined   = 0;
	$ioadapter = 0;
	$mdqueue   = 0;
    }
    if (/^sub .*\}/ || /^\}/o) {
	$in_sub = 0;
    }

    if ($in_sub) {
	$buf .= $_;
    }

    $prev_line = $_;
}

exit 0;


# Descriptions: check if $buf matches FNF style.
#    Arguments: STR($buf)
# Side Effects: update $reason
# Return Value: NUM
sub _is_fnf
{
    my ($buf) = @_;
    my $found = 0;
    my $is_arg = 0;
    my %type  = (
		 "Descriptions" => 0, 
		 "Arguments"    => 0, 
		 "Side Effects" => 0, 
		 "Return Value" => 0, 
		 );
    undef $reason;

    # special trap
    if ($buf =~ /\#\s+Descriptions:\s*\n\#\s+\S+/m) {
	$found |= 1;
	$type{ "Descriptions" } = 1;
    }

    for (split(/\n/, $buf)) {
	if (/\#\s+Descriptions:\s+\S+/o) { 
	    $found |= 1;
	    $type{ "Descriptions" } = 1;
	    $is_arg = 0;
	}
	if (/\#\s+Arguments:\s+\S+/o) { 
	    $found |= (1 << 1);
	    $type{ "Arguments" } = 1;
	    $is_arg = 1;
	}
	if (/\#\s+Side Effects:\s+\S+/o) { 
	    $found |= (1 << 2);
	    $type{ "Side Effects" } = 1;
	    $is_arg = 0;
	}
	if (/\#\s+Return Value:\s+\S+/o) { 
	    $found |= (1 << 3);
	    $type{ "Return Value" } = 1;
	    $is_arg = 0;
	}

	# hold argument buffer
	$fnf_args .= $_ if $is_arg;
    }

    if ($found == 15) {
	return 1;
    }
    else {
	for my $key (keys %type) {
	    unless ($type{ $key }) {
		$reason .= $reason ? ",$key" : $key;
	    }
	}

	if ($found == 0) {
	    $reason = "no comment lines";
	}

	return 0;
    }
}


# Descriptions: check consistency between @_ and FNF Arguments.
#    Arguments: STR($prog) STR($buf)
# Side Effects: none
# Return Value: none
sub _check_args
{
    my ($prog, $buf) = @_;
    my $fnf = $fnf_args;

    $buf =~ s/^\s*//;
    $buf =~ s/\s*$//;

    # my ( ... ) = @_;
    unless ($buf =~ /^my\s*\(/) {
	print "\n$prog\n   $cur_fn\n\tmissing my()? $buf\n\n";
	return;
    }

    $buf =~ s/my\s*\(//;
    $buf =~ s/\)\s*=.*$//;

    my (@args) = split(/\s*,\s*/, $buf);

    # FNF
    my (@fnf) = ();
    $fnf =~ s/\#//g;
    $fnf =~ s/\n/    /g;

    for (split(/\s+/, $fnf)) {
	s/\[//g;
	s/\]//g;
	if (/^\w+\((\S+)\)/) {
	    push(@fnf, $1);
	}
    }

    my $bad = 0;
    if ($#args != $#fnf) {
	$bad = 1;
    }
    else {
	for (my $i = 0; $i <= $#args; $i++) {
	    if ($args[ $i ] ne $fnf[ $i ]) {
		$bad = 1;
	    }
	}
    }

    if ($bad) {
	print "\n$prog\n   $cur_fn\n\twrong arguments\n";
	print "\tFNF  @fnf\n";
	print "\t\@_   @args\n";
	print "\n";
    }
}


# Descriptions: set hash at %implicit
#    Arguments: STR($key) STR($file) STR($buf)
# Side Effects: update %implicit
# Return Value: none
sub _log
{
    my ($key, $file, $buf) = @_;

    $buf =~ s/^\s*//;
    $implicit->{ $key }->{ $file } .= "\t ($count)> ".$buf;
}


# Descriptions: show value of %implicit for the specified $file.
#    Arguments: STR($file)
# Side Effects: none
# Return Value: none
sub _info
{
    my ($file) = @_;
    my %type = (
		'use_underbar' => 'use of $_',
		'if_style'     => 'wrong style: if',
		'for_style'    => 'wrong style: for',
		);

    for my $key (sort keys %$implicit) {
	if ($implicit->{ $key }->{ $file }) {
	    print "\n$file\n";
	    print "\t", $type{ $key } ,"\n";
	    print $implicit->{ $key }->{ $file };
	}
    }
}
