# -*-Perl-*-
################################################################
###
###			       Grep.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Nov 03, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::Grep.pm version 20000414(IM141)";

package IM::Grep;
require 5.003;
require Exporter;

use IM::Config;
use IM::Util;
use IM::Folder qw(message_list message_range);
use IM::Japanese;
use IM::EncDec qw(mime_decode_string);
use integer;
use strict;
use vars qw(@ISA @EXPORT %MESSAGE_ID_HASH);

@ISA = qw(Exporter);
@EXPORT = qw(parse_expression grep_folder sortuniq);

=head1 NAME

Grep - IM grep folder

=head1 DESCRIPTION


=head1 SYNOPSIS

use IM::Grep;

$eval_string = &parse_expression($expression, $casefold);

@message_number_array = &grep_folder($folder_dir, $eval_string, @ranges);

=cut

##
## Environments
##

# regexp for range syntax (sequence not supported)
my $range_element = '(\\d+|first|last|next|prev|new)';
my $range_regexp = "($range_element(-$range_element|:[+-]?\\d+)?|all)";

# end of header in draft message
my $draft_delimiter = "\n----\n";

%MESSAGE_ID_HASH = ();

sub grep_folder ($$$@) {
    my ($folder, $eval_string, $dup_check, @ranges) = @_;
    my $folder_dir;
    my @src_msgs = ();
    my @messages = ();

    if ( $folder =~ /^\-/ ) {
	im_warn("Newsspool $folder search not supported (ignored)\n");
    }

    im_debug("Going on $folder range @ranges\n") if &debug('all');

    $folder_dir = expand_path($folder);

    chdir($folder_dir) or
	im_die("unable to change directory to $folder_dir: $!\n");

    im_debug("entered $folder_dir\n") if &debug('all');

    # collect message numbers
    my @filesinfolder = message_list($folder_dir);
    foreach ( @ranges ) {
	my @tmp = ();
	im_die("illegal range specification: $_\n")
	    unless /^$range_regexp$/;
	im_debug("extract range $_\n") if &debug('all');
	if (( @tmp = message_range($folder, $_,  @filesinfolder )) eq '') {
	    im_warn("message $_ out of range\n");
	}
	push(@src_msgs, @tmp);
    }

    im_debug("extracted messages \"@src_msgs\"\n") if &debug('all');

    @src_msgs = sortuniq(@src_msgs);

    im_debug("uniqified messages \"@src_msgs\"\n") if &debug('all');

    # dirty quick hack to determine what part is required
    # should be implemented better
    my(%find) = ('head' => scalar($eval_string =~ /\$head\s*=~/),
		 'body' => scalar($eval_string =~ /\$body\s*=~/),
		 'all'  => scalar($eval_string =~ /\$all\s*=~/));

    my $m;
    foreach $m (@src_msgs) {
	my($all, $head, $body) = ('', '', '');
	local($/);

	unless (im_open(\*MES, "< $m")) {
	    if (! $main::opt_quiet) {
		im_warn("message $m not exists: $!\n");
	    }
	    next;
	}

	# read $head anyway
	#
	$/ = '';
	$head = <MES>;

	# if the header contains draft-style header delimiter,
	# truncate the header and seek to the beginning of body.
	my $p = index($head, $draft_delimiter);
	if ($p >= 0) {
	    seek(MES, $p + length($draft_delimiter), 0);
	    substr($head, $p + 1) = '';
	}
	if ($find{'head'} || $find{'all'}) {
	    $head =~ s/\n\s+/ /g; # fix continuation lines
	    $head = mime_decode_string($head);
	}

	# read $body if necessary
	#
	undef $/;
	if ($find{'body'}) {
	    $body = <MES>;
	}

	# construct $all if necessary
	#
	if ($find{'all'}) {
	    $all = $head . ($body ? $body : scalar(<MES>));
	}

	close(MES);

	if ($eval_string || $dup_check eq 'none') {
	    if (eval $eval_string) {
		push(@messages, $m);
	    }
	} else {
	    # check dupulicate message-id
	    $head =~ m/Message-id:\s*<(.*)>/i;
	    my $msgid = $1;
	    $head =~ m/Subject:\s*(.*)/i;
	    my $subject = $1;

	    if ($dup_check eq "" || $dup_check eq "message-id") {
		if ($MESSAGE_ID_HASH{$msgid}++) {
		    push(@messages, $m);
		}
	    } elsif ($dup_check eq "message-id+subject") {
		my $t = join(";", $msgid, $subject);
		if ($t ne ";" and $MESSAGE_ID_HASH{$t}++) {
		    push(@messages, $m);
		}
	    }
	}
    }

    return @messages;
}


##################################################
##
## Parse expression
##

sub EOL     { 0; }
sub LITERAL { 1; }
sub SYMBOL  { 2; }

sub parse_expression ($$) {
    my ($expr, $casefold) = @_;

    my $case_flag = '';
    my $expr_string = '';
    my $eval_string = '';

    $case_flag = 'i' if ($casefold);

    # split into tokens
    
    my $STOPCHARS = '(["\']|\\\\(?:.|$)|\s*(?:[!()=]|\&\&?|\|\|?)\s*)';
    my $SYMBOLS = '[!()=]|\&\&?|\|\|?';

    my @tokens = ();
    my ($escape, $pos, $len) = (0) x 3;
    my ($token, $quote) = ('') x 2;

    my $str;
  LEX:
    foreach $str (split($STOPCHARS, $expr)) {

	next LEX if ($str eq '');

	# process quoted string
	if ($quote ne '') {
	    if ($quote eq $str) {
		$quote = '';
		$len++;
		next LEX;
	    }
	    $token .= $str;
	    $len += length($str);
	    next LEX;
	}

	# escaping
	if ($str eq '\\') {
	    parse_die('Unexpected end of line', $expr, $pos + 1);
	}
	if ($str =~ /\\(.)/) {
	    $token .= $1;
	    $len += 2;
	    next LEX;
	}
	
	# quoting
	if ($str =~ /^[\'\"]$/) {
	    $quote = $str;
	    $len++;
	    next LEX;
	}

	if ($str =~ /^\s*($SYMBOLS)\s*$/) {
	    if ($token ne '') {
		push(@tokens, [LITERAL, $token, $pos - $len]);
		$token = '';
		$len = 0;
	    }
	    push(@tokens, [SYMBOL, $1, $pos + index($str, $1)]);
	    next LEX;
	}

	$token .= $str;
	$len += length($str);

    } continue {
	$pos += length($str);
    }				# end of LEX:

    # flush remaining literal
    if ($token ne '') {
	push(@tokens, [LITERAL, $token, $pos - $len]);
	$token = '';
    }

    if ($quote ne '') {
	parse_die('Quoting not closed', $expr, $pos);
    }

    push(@tokens, [EOL, '', $pos]); # end of line

    # automaton status:
    # <empty expression not permitted>
    #
    # 0: before expression: '('->0, '!'->0, LITERAL->2, EOL->end
    # 1: after expression: ')'->0, '|'->0, '&'->0, EOL->end
    # 2: after field: '='->3, others ->error
    # 3: before pattern: LITERAL->1, fallback to 1
    #

    my ($status, $paren) = (0) x 2;
    my ($field, $pattern, $string) = ('') x 3;

#    my $token;
  PARSE:
     foreach $token (@tokens) {
	
#	 print "$token->[0]:$token->[1]:$status\n";
	 
	 if ($status == 0) {
	     if ($token->[0] == LITERAL) {
		 $status = 2;
		 $field = $token->[1];
		 next PARSE;
	     }
	     if ($token->[0] == EOL) {
		 last PARSE;
	     }
	     if ($token->[1] eq '(') {
		 $paren++;
		 $eval_string .= '(';
		 next PARSE;
	     }
	     if ($token->[1] eq '!') {
		 $eval_string .= 'not ';
		 next PARSE;
	     }
	     parse_die('Unexpected symbol', $expr, $token->[2]);
	 }
	 if ($status == 1) {
	     if ($token->[0] == LITERAL) {
		 parse_die('Syntax error', $expr, $token->[2]);
	     }
	     if ($token->[0] == EOL) {
		 last PARSE;
	     }
	     if ($token->[1] eq ')') {
		 if (--$paren < 0) {
		     parse_die('Unbalanced parenthesis', $expr, $token->[2]);
		 }
		 $eval_string .= ')';
		 $status = 1;
		 next PARSE;
	     }
	     if ($token->[1] =~ /&/) {
		 $eval_string .= 'and ';
		 $status = 0;
		 next PARSE;
	     }
	     if ($token->[1] =~ /\|/) {
		 $eval_string .= 'or ';
		 $status = 0;
		 next PARSE;
	     }
	     parse_die('Unexpected symbol', $expr, $token->[2]);
	 }
	 if ($status == 2) {
	     if ($token->[0] == SYMBOL and $token->[1] eq '=') {
		 $status = 3;
		 next PARSE;
	     }
	     parse_die('Missing \'=\'', $expr, $token->[2]);
	 }
	 if ($status == 3) {
	     if ($token->[0] == LITERAL) {
		 $pattern = $token->[1];
	     }
	     $field =~ s/([@\/])/\\$1/g;

	     $pattern = make_japanese_pattern($pattern);
	     if ($field eq 'body') {
		 $pattern = "." unless $pattern;
		 $string = "\$$field =~ /$pattern/om$case_flag";
	     } elsif ($field =~ /^(all|head)$/) {
		 $pattern = "." unless $pattern;
		 $string = "\$$field =~ /$pattern/om$case_flag";
	     } elsif ($field ne '') {
		 $string = "\$head =~ /^$field:.*$pattern/om$case_flag";
	     } else {
		 parse_die('Search pattern not specified', $expr, $token->[2]);
	     }

	     $status = 1;
	     $eval_string .= "$string ";
	     $field = '';
	     $pattern = '';
	     $string = '';
	     
	     if ($token->[0] == LITERAL) {
		 next PARSE;
	     }
	     redo PARSE;
	 }
     }				# end of PARSE:

    if ($paren > 0) {
        parse_die('Parenthesis not closed', $expr, length($expr));
    }
    
# simple check by perl interpreter
    my ($head, $body, $all) = ('') x 3;
    eval "$eval_string";
    if ($@) {
	if ($main::opt_quiet) {
	    exit $EXIT_ERROR;
	}
	if ($main::opt_verbose) {
	    im_die("something wrong with the expression:\n$@");
	}
	im_die("something wrong with the expression\n");
    }
    
#    print "$eval_string\n"; exit 0;
    return $eval_string;
}    

sub parse_die($$$) {
    my ($die, $expr, $pos) = @_;
    if (!$main::opt_quiet and !$main::opt_verbose) {
	im_die("$die in the expression\n");
    }
    if (!$main::opt_quiet and $main::opt_verbose) {
	im_die("$die\n$expr\n" . (" " x $pos) . "^\n");
    }
    exit $EXIT_ERROR;
}
    

##################################################
##
## sort and uniqify a list
##

sub sortuniq (@) {
    my(@target) = @_;
    my(%tmp);

    @tmp{@target} = (undef) x @target;
    return ( sort {$a <=> $b} keys %tmp );
}

##################################################
##
## multi-line and Japanese string search
##

my @in  = ('\e\$\@', '\e\$B');
my @out = ('\e\(J',  '\e\(B');
my $in  = join('|', (@in));
my $out = join('|', (@out));
my $shiftcode  = '(' . join('|', @in, @out) . ')';
my $chargap = '(' . join('|', @in, @out, '\s'). ')*';

sub make_japanese_pattern {
    my $pat = shift;
    my $result = '';
    my $jis = 0;

    #
    # If the parameter contains EUC or SJIS string, convert it to
    # ISO-2022-JP code.  Probably this should be done in imgrep with
    # user specified original code rather than expecting it.
    #
    if ($pat =~ /[\201-\376]/) {
	$pat = IM::Japanese::conv_iso2022jp($pat, 'NoHankana');
    }

    for (split(/$shiftcode/, $pat)) {
	if (/$in/o)  {
	    $jis = 1;
	    $result .= $chargap if $result;
	}
	elsif (/$out/o) {
	    $jis = 0;
	}
	elsif ($jis) {
	    $result .= join($chargap, map(quotemeta, m/../g));
	}
	else {
	    #
	    # Replace space characters by \s*.  This enables to find
	    # several word sequence across line boundary.
	    #
	    s/(.)/$1 =~ m@\s@ ? '\\s*' : quotemeta($1)/eg;
	    $result .= $_;
	}
    }

    length($result) ? $result : undef;
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
