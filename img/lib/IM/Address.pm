# -*-Perl-*-
################################################################
###
###			      Address.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Feb 28, 2000
###

my $PM_VERSION = "IM::Address.pm version 20000228(IM140)";

package IM::Address;
require 5.003;
require Exporter;

use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(extract_addr replace_addr fetch_addr);

=head1 NAME

Address - RFC822 style address parser

=head1 SYNOPSIS

  use IM::Address;

  $pure_address_portion = &extract_addr($address_with_comment);

  $replaced_address = &replace_addr($original_address_with_comment,
	$pure_notation_of_old_address, $pure_notation_of_new_address);

  ($first, $rest) = &fetch_addr($address_list, $pure_address_flag);

=head1 DESCRIPTION

  $a = "Motonori Nakamura <motonori\@econ.kyoto-u.ac.jp>";
  &extract_addr($a) returns "motonori@econ.kyoto-u.ac.jp".

  $a = "Motonori Nakamura <motonori\@econ.kyoto-u.ac.jp>";
  $b = "motonori\@econ.kyoto-u.ac.jp";
  $c = "motonori\@wide.ad.jp";
  &replace_addr($a, $b, $c) returns "Motonori Nakamura <motonori@wide.ad.jp>".

  $a = "kazu, nom, motonori";
  &fetch_addr($a, 0) returns ("kazu", " nom, motonori").

=cut

use vars qw($FOR_SMTP); # sub fetch_addr

##### EXTRACT AN ADDRESS FROM AN ADDRESS EXPRESSION #####
#
# extract_addr(address)
#	address: an address in any style
#	return values: pure address portion (NULL if error)
#
sub extract_addr ($) {
    my $addrin = shift;

    $addrin =~ s/\n\s+//g;
    return (&fetch_addr($addrin, 1))[0];	# strip ()-style comment
}

##### REPLACE THE ADDRESS IN AN ADDRESS EXPRESSION #####
#
# replace_addr(expr, old, new)
#	expr:
#	old:
#	new:
#	return value: replaced expression
#
sub replace_addr ($$$) {
    my ($expr, $old, $new) = @_;
    my $qold = quotemeta($old);

    if ($expr =~ /$qold.*$qold/) {
	# multiple appearance
	return $new;	# XXX drop comment portion
    }
    $expr =~ s/$qold/$new/;
    return $expr if (&extract_addr($expr) eq $new);
    # something wrong. why?
    return $new;	# XXX drop comment portion
}

##### GET FIRST ADDRESS #####
#
# sub fetch_addr(addr_list, extract)
#	addr_list: address list string (concatinated with ",")
#	extract: extract pure address portion
#	return values: (first, rest, friendly)
#	  first: the first address in the list (NULL if error)
#	  rest: rest of address in the list
#	  friendly: user friendly portion of the first address
#
sub fetch_addr ($$) {
    my ($addrin, $extract) = @_;
    my ($addrout, $pureout, $groupsyntax) = ('', '', '');
    my ($friendly1, $friendly2, $c) = ('', '', '');
    my ($inquote, $incomment, $addrquote) = (0, 0, 0);
    my ($gotpure, $groupcolon, $route) = (0, 0, 0);
    im_debug("fetch_addr(in): $addrin\n") if (&debug('addr'));
    $FOR_SMTP = (&progname =~ /imput/i) unless (defined($FOR_SMTP));
    $addrin = '' unless (defined($addrin));
    $route = 1 if ($addrin =~ /^\@/);
    while ($addrin ne '') {
	if ($addrin =~ /^([^\e"\\()<>:;,]+)(.*)/s) {
	    $c = $1;
	    $addrin = $2;
	} elsif ($addrin =~ /^\e/) {
	    if ($FOR_SMTP) {
		im_err("ESC sequence not allowed in address expression\n");
		return ('', '', '');
	    } else {
		if ($addrin =~ /^(\e[^\e]+\e\([BJ])(.*)/s) {
		    $c = $1;
		    $addrin = $2;
		} else {
		    ($c, $addrin) = unpack('a a*', $addrin);
		}
	    }
	} else {
	    ($c, $addrin) = unpack('a a*', $addrin);
	}

	last if ($c eq ',' && !$inquote && !$incomment && !$groupcolon
	         && !$route);
	$friendly2 .= $c unless($addrquote);
	if ($inquote) {
	    $addrout .= $c;
	    $pureout .= $c unless ($gotpure);
	    if ($c eq '"') {
		$inquote = 0;
	    } elsif ($c eq '\\') {
		($c, $addrin) = unpack('a a*', $addrin);
		$addrout .= $c;
		$pureout .= $c unless ($gotpure);
		$friendly2 .= $c unless($addrquote);
	    }
	    next;
	} elsif ($incomment) {
	    $addrout .= $c unless ($extract);
	    $friendly1 .= $c;
	    if ($c eq '(') {
		$incomment++;
	    } elsif ($c eq ')') {
		$incomment--;
	    } elsif ($c eq '\\') {
		($c, $addrin) = unpack('a a*', $addrin);
		$friendly1 .= $c;
		$friendly2 .= $c unless($addrquote);
		$addrout .= $c unless ($extract);
	    }
	    chop($friendly1) unless ($incomment);
	    next;
	} elsif ($c eq '"') {
	    $inquote = 1;
	} elsif ($c eq '(') {
	    $incomment++;
	    next if ($extract);
	} elsif ($c eq ')') {
	    im_err('Unbalanced comment parenthesis '
	      ."('(', ')'): $addrout -- $addrin\n");
	    return ('', '', '');
	} elsif ($c eq '<') {
	    $gotpure = 0;
	    $pureout = '';
	    chop($friendly2) unless ($addrquote);
	    $addrquote++;
	    $route = 1 if ($addrin =~ /^\@/);
	} elsif ($c eq '>') {
	    $gotpure = 1;
	    $pureout =~ s/^<//;
	    $addrquote--;
	    $route = 0;
	} elsif ($c eq '\\') {
	    $addrout .= $c;
	    $pureout .= $c unless ($gotpure);
	    ($c, $addrin) = unpack('a a*', $addrin);
	    $friendly2 .= $c unless($addrquote);
	} elsif ($c eq ':') {
	    $addrout .= $c;
	    $pureout .= $c unless ($gotpure);
	    if ($addrin =~ /^([^"\()<>:;,]+)(.*)/s) {
		$c = $1;
		$addrin = $2;
	    } else {
		($c, $addrin) = unpack('a a*', $addrin);
	    }
	    $friendly2 .= $c unless($addrquote);
	    $groupcolon = 1 if ($c ne ':');
	} elsif ($c eq ';') {
	    if ($groupcolon) {
		$groupcolon = 0;
		$groupsyntax = 1;
	    }
	} elsif ($c eq ',') {
	    last unless ($groupcolon || $route);
	}
	$addrout .= $c;
	$pureout .= $c unless ($gotpure);
    }
    im_debug("fetch_addr(out): $addrout\n") if (&debug('addr'));
    if ($addrquote) {
	im_err("Unbalanced address quotes ('<', '>'): $addrout\n");
	return('', '', '');
    }
    if ($inquote) {
	im_err("Unbalanced quotes ('\"'): $addrout\n");
	return('', '', '');
    }
    if ($incomment) {
	im_err("Unbalanced comment parenthesis ('(', ')'): $addrout\n");
	return('', '', '');
    }
    if ($extract && !$groupsyntax) {
	if ($addrout =~ /<.*>/) {
	    $addrout = $pureout;
	    $friendly1 = $friendly2;
	}
	$addrout =~ s/^\s+//;
	$addrout =~ s/\s+$//;
	$friendly1 =~ s/^\s+//;
	$friendly1 =~ s/\s+$//;
    }
    return ($addrout, $addrin, $friendly1);
}

1;

### Copyright (C) 1997, 1998, 1999 IM developing team
### All rights reserved.
### 
### Redistribution and use in source and binary forms, with or without
### modification, are permitted provided that the following conditions
### are met:
### 
### 1. Redistributions of source code must retain the above copyright
###    notice, this list of conditions and the following disclaimer.
### 2. Redistributions in binary form must reproduce the above copyright
###    notice, this list of conditions and the following disclaimer in the
###    documentation and/or other materials provided with the distribution.
### 3. Neither the name of the team nor the names of its contributors
###    may be used to endorse or promote products derived from this software
###    without specific prior written permission.
### 
### THIS SOFTWARE IS PROVIDED BY THE TEAM AND CONTRIBUTORS ``AS IS'' AND
### ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
### IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
### PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE TEAM OR CONTRIBUTORS BE
### LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
### CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
### SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
### BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
### WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
### OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
### IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
