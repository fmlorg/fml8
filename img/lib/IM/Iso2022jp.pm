# -*-Perl-*-
################################################################
###
###			     Iso2022jp.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::Iso2022jp.pm version 20000414(IM141)";

package IM::Iso2022jp;
require 5.003;
require Exporter;

use IM::Util;
use IM::EncDec qw(b_encode_string q_encode_string);
use IM::Japanese qw(code_check conv_iso2022jp);
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(set_debug_encode
	struct_iso2022jp_mimefy
	line_iso2022jp_mimefy
	header_iso2022jp_conv
);

=head1 NAME

Iso2022jp - MIME header encoder for ISO-2022-JP character set

=head1 SYNOPSIS

use IM/Iso2022jp;

$encoded_string_for_structured_header = struct_iso2022jp_mimefy(string);

$encoded_string_for_unstructured_header = line_iso2022jp_mimefy(string);

$rcode = header_iso2022jp_conv(\@Header, code_conv_flag);

=head1 DESCRIPTION

=cut

use vars qw($Jp_Bin $Jp_Qin $Jp_out
	    $Jis_kanji $Jis_roman
	    $C_pascii);
($Jp_Bin, $Jp_Qin, $Jp_out) = ('=?ISO-2022-JP?B?', '=?ISO-2022-JP?Q?', '?=');
($Jis_kanji, $Jis_roman) = ('\e\$[\@B]', '\e\([BJ]');
$C_pascii = '[\x21-\x7e]+';

BEGIN {
    $main::Folding_length = 72 unless (defined($main::Folding_length));
}

##### STRUCTURED HEADER LINE ISO-2022-JP MIME CONVERSION #####
#
# struct_iso2022jp_mimefy(lines)
#	lines: continuous header lines to be converted
#	return value: (lines, err)
#	  lines: converted lines (NULL if error)
#
sub struct_iso2022jp_mimefy ($) {
    my $line_in = shift;
    my ($c, $groupsyntax);
    my ($inquote, $incomment, $addrquote) = (0, 0, 0);
    my ($groupcolon, $need_space, $need_encode) = (0, 0, 0);
    my ($line_out, $line_work) = ('', '');
    my ($n);
    im_debug("encoding structured: $line_in\n") if (&debug('encode'));
    while ($line_in ne '') {
	if ($line_in =~ /^($Jis_kanji[^\e]+$Jis_roman([ \t]*$Jis_kanji[^\e]+$Jis_roman)*)(.*)/os){
	    $c = $1;
	    $line_in = $3;
	    $need_encode = 1;
	} elsif ($line_in =~ /^($Jis_roman)(.*)/os) {	# XXXX
	    $c = $1;
	    $line_in = $2;
	    $need_encode = 1;
	} else {
	    ($c, $line_in) = unpack('a a*', $line_in);
	}
	if (!$inquote && $c =~ /^\s$/) {
	    # split/encode
	    if ($line_work ne '' && $need_encode) {
		$need_encode = 0;
		$line_out =~ /([^\n]*)$/;
		$n = length($1);
		$line_out .= &word_iso2022jp_mimefy($n, $line_work,
						    $need_space, 1).$c;
	    } else {
		$line_out = &hdr_cat($line_out, $line_work.$c, '');
	    }
	    $line_work = '';
#	    $need_space = 0;
	    next;
	} elsif ($inquote) {
	    $line_work .= $c;
	    if ($c eq '"') {
		$inquote = 0;
	    } elsif ($c eq '\\') {
		my $tmp;
		($tmp, $line_in) = unpack('a a*', $line_in);
		$line_work .= $tmp;
	    }
	    next;
	} elsif ($incomment) {
	    if ($c eq '(') {
		$incomment++;
	    } elsif ($c eq ')') {
		$incomment--;
		if ($incomment == 0) {
		    # encode
		    if ($line_work ne '' && $need_encode) {
			$need_encode = 0;
			$line_out =~ /([^\n]*)$/;
			$n = length($1);
			$line_out .= &word_iso2022jp_mimefy($n, $line_work,
							    $need_space, 1).$c;
		    } else {
			$line_out = &hdr_cat($line_out, $line_work.$c, '');
		    }
		    $line_work = '';
		    $need_space = 1;
		    next;
		}
	    } elsif ($c eq '\\') {
		$line_work .= $c;
		($c, $line_in) = unpack('a a*', $line_in);
	    }
	    $line_work .= $c;
	    next;
	} elsif ($c eq '"') {
	    $inquote = 1;
	} elsif ($c eq '(') {	# beggining of a comment
	    $incomment++;
	    # encode and split
	    if ($line_work ne '' && $need_encode) {
		$need_encode = 0;
		$line_out =~ /([^\n]*)$/;
		$n = length($1);
		$line_out .= &word_iso2022jp_mimefy($n, $line_work, 0, 1).$c;
	    } else {
		$line_out = &hdr_cat($line_out, $line_work.$c, '');
	    }
	    $line_work = '';
	    $need_space = 0;
	    next;
	} elsif ($c eq ')') {
	    im_err("Unbalanced comment parenthesis ('(', ')'): "
		   ."$line_out$line_work -- $c -- $line_in\n");
#	    &error_exit;
	    return '';
	} elsif ($c eq '<') {
	    # encode
	    $addrquote++;
	    if ($addrquote == 1) {
		if ($line_work ne '' && $need_encode) {
		    $need_encode = 0;
		    $line_out =~ /([^\n]*)$/;
		    $n = length($1);
		    $line_work = &word_iso2022jp_mimefy($n, $line_work,
							$need_space, 1).' ';
		    $line_out .= $line_work;
		} else {
		    $line_out = &hdr_cat($line_out, $line_work, '');
		}
		$line_work = $c;
		$need_space = 1;
		next;
	    }
	} elsif ($c eq '>') {
	    $addrquote--;
	    if ($addrquote == 0) {
		# split
		$line_out = &hdr_cat($line_out, $line_work.$c, '');
		$line_work = '';
		$need_space = 1;
		next;
	    }
	} elsif ($c eq '\\') {
	    $line_work .= $c;
	    ($c, $line_in) = unpack('a a*', $line_in);
	} elsif ($c eq ':') {
	    $line_work .= $c;
	    ($c, $line_in) = unpack('a a*', $line_in);
	    $groupcolon = 1 if ($c ne ':');
	} elsif ($c eq ';') {
	    if ($groupcolon) {
		$groupcolon = 0;
		$groupsyntax = 1;
	    }
	} elsif ($c eq ',') {
	    unless ($groupcolon) {
		# trail
		if ($line_work ne '' && $need_encode) {
		    $need_encode = 0;
		    $line_out =~ /([^\n]*)$/;
		    $n = length($1);
		    $line_out .= &word_iso2022jp_mimefy($n, $line_work,
							$need_space, 1).' '.$c;
		} else {
		    $line_out = &hdr_cat($line_out, $line_work.$c, '');
		}
		$line_work = '';
		$need_space = 1;
		next;
	    }
	}
	$line_work .= $c;
    }
    # trail
    if ($line_work ne '' && $need_encode) {
	$need_encode = 0;
	$line_out =~ /([^\n]*)$/;
	$n = length($1);
	$line_out .= &word_iso2022jp_mimefy($n, $line_work, $need_space, 1);
    } else {
	$line_out = &hdr_cat($line_out, $line_work, '');
    }
    im_debug("encoded structured: $line_out\n") if (&debug('encode'));
    if ($addrquote) {
	im_err("Unbalanced address quotes ('<', '>'): $line_out\n");
#	&error_exit;
	return '';
    }
    if ($inquote) {
	im_err("Unbalanced quotes ('\"'): $line_out\n");
#	&error_exit;
	return '';
    }
    if ($incomment) {
	im_err("Unbalanced comment parenthesis ('(', ')'):  $line_out\n");
#	&error_exit;
	return '';
    }
    if ($line_out =~ /$Jis_kanji[^\e]+$Jis_roman/o){
	im_err("invalid iso-2022-jp charset location in structured field: "
	       . "$line_out\n");
#	&error_exit;
	return '';
    }
    return $line_out;
}

##### UNSTRUCTURED HEADER LINE ISO-2022-JP MIME CONVERSION #####
#
# line_iso2022jp_mimefy(lines)
#	lines: continuous header lines to be converted
#	return value: converted lines
#
sub line_iso2022jp_mimefy ($) {
    my ($line_in) = @_;
    my ($line_out, $this_word, $this_space, $this_code, $follow, $n);
    $follow = 0;
    $this_space = '';
    $line_out = '';
    im_debug("encoding unstructured: $line_in\n") if (&debug('encode'));
    while ($line_in ne '') {
	if ($line_in =~ /^\n([ \t]*)(.*)/s) {	# fold headdings
	    $line_in = $2;
	    if ($this_space ne '') {
		$line_out .= $this_space;
		$this_space = '';
	    }
	    if ($1 ne '') {
		$line_out .= "\n$1";
	    } else {
		$line_out .= "\n";
	    }
	    $follow = 0;
	    next;
	}
	$this_space = '';
	if ($line_in =~ /^([ \t]+)(.*)/s) {	# just spaces
	    $line_in = $2;
	    $this_space = $1;
	}
	$this_word = '';
	$this_code = 'us-ascii';
	while ($line_in ne '') {
	    if ($line_in =~ /^($C_pascii)(.*)/os) {
		$line_in = $2;
		$this_word .= $1;
	    } elsif ($line_in =~ /^($Jis_kanji[^\e]+$Jis_roman([ \t]*$Jis_kanji[^\e]+$Jis_roman)*)(.*)/os) {
		last
		  if ($this_code ne 'us-ascii' && $this_code ne 'iso-2022-jp');
		$line_in = $3;
		$this_word .= $1;
		$this_code = 'iso-2022-jp';
	    } elsif ($line_in =~ /^($Jis_roman)(.*)/os){	# XXX
		last
		  if ($this_code ne 'us-ascii' && $this_code ne 'iso-2022-jp');
		$line_in = $2;
		$this_word .= $1;
		$this_code = 'iso-2022-jp';
	    } elsif ($line_in =~ /^[ \t]+/) {	# just spaces
		last;
	    } elsif ($line_in =~ /^\n[ \t]*/) {	# fold headdings
		last;
	    } else {
		# anything else (XXX should be Q-encoded?)
		last if ($this_code ne 'us-ascii' && $this_code ne 'unknown');
		(my $tmp, $line_in) = unpack('a a*', $line_in);
		$this_word .= $tmp;
		$this_code = 'unknown';
	    }
	}
	if ($this_code eq 'us-ascii' || $this_code eq 'unknown') {
	    $line_out = &hdr_cat($line_out, $this_word, $this_space);
	    $this_space = '';
	    $follow = 0;
	} elsif ($this_code eq 'iso-2022-jp') {
	    # ISO-2022-JP encoding
	    im_debug("encoding: $this_word\n") if (&debug('encode'));
	    if ($this_space ne '') {
		if ($follow) {
		    $this_word = $this_space . $this_word;
		} else {
		    $line_out .= $this_space;
		}
	    }
	    $line_out =~ /([^\n]*)$/;
	    $n = length($1);
	    $line_out .= &word_iso2022jp_mimefy($n, $this_word, $follow, 0);
	    $this_space = '';
	    $follow = 1;
	}
    }
    return $line_out;
}

##### WORD ISO-2022-JP MIME CONVERSION #####
#
# word_iso2022jp_mimefy(size, word, need_pre_space, struct)
#	size: length already occupied in the last line
#	word: word to be converted
#	need_pre_space: space should be prepended
#	struct: true if in structured field
#	return value: encoded words
#
sub word_iso2022jp_mimefy ($$$$) {
    my ($size, $word_in, $need_pre_space, $struct) = @_;
    my ($word_out) = '';
    my ($word_conv, $n, $word_sub, $word_rest);

    if ($main::NoFolding) {
	if ($main::HdrQEncoding) {
	    $word_out .= $Jp_Qin;
	    $word_out .= &q_encode_string($word_in, $struct);
	} else {
	    $word_out .= $Jp_Bin;
	    $word_out .= &b_encode_string($word_in);
	}
	$word_out .= $Jp_out;
	return $word_out;
    }

    $size = $main::Folding_length - $size;
    im_debug("encoding word($size): $word_in\n") if (&debug('encode'));
    if ($size - length($Jp_Bin) - length($Jp_out) - 12 <= 0) {
	$word_out .= "\n\t";
	$size = $main::Folding_length;
    } elsif ($need_pre_space) {
	$word_out .= ' ';
    }
    while ($word_in ne '') {
	$word_conv = '';
	$word_out =~ /([^\n]*)$/;
	$n = int(($size - (length($1) + length($Jp_Bin)
			   + length($Jp_out) + 12))/4*3);
	while (($n > 0) && $word_in ne '') {
#	    if ($word_in !~ /$Jis_kanji/o) {
#		# us-ascii part
#		($word_sub, $word_in) = unpack("a$n a*", $word_in);
#		$word_conv .= $word_sub;
#		$n -= length($word_sub);
#		next;
#	    }
	    if ($word_in =~ /^([^\e]+)(.*)/s) {
		# us-ascii part
		($word_sub, $word_in) = unpack("a$n a*", $1);
		$word_in .= $2;
		$word_conv .= $word_sub;
		$n -= length($word_sub);
		next;
	    } elsif ($word_in =~ /^($Jis_roman)([^\e]+)(.*)/s) {
		# JIS roman part
		if ($n < 3) {
		    $n = 0;
		    next;
		}
		($word_sub, $word_in) = unpack("a$n a*", $2); # work_in?
		$word_sub = $1 . $word_sub;
		$word_in .= $3;
		$word_conv .= $word_sub;
		$n -= length($word_sub);
		next;
	    } elsif ($word_in =~ /($Jis_kanji)([^\e]+)($Jis_roman)(.*)/os) {
		# iso-2022-jp part
		$n = int($n/2)*2 - 6;
		if ($n < 2) {
		    $n = 0;
		    next;
		}
		($word_sub, $word_rest) = unpack("a$n a*", $2);
		if ($word_rest) {
		    $word_in = "$1$word_rest$3$4";
		} else {
		    $word_in = $4;
		}
		$word_conv .= "$1$word_sub$3";
		$n -= length($word_sub)+6;
		next;
	    } else {
		# Unsupported charset (XXX)
		$word_conv .= $word_in;
		$word_in = '';
	    }
	}
	if ($word_conv ne '') {
	    if ($main::HdrQEncoding) {
		$word_out .= $Jp_Qin;
		$word_out .= &q_encode_string($word_conv, $struct);
	    } else {
		$word_out .= $Jp_Bin;
		$word_out .= &b_encode_string($word_conv);
	    }
	    $word_out .= $Jp_out;
	}
	if ($word_in ne '') {
	    $word_out .= "\n\t";
	}
	$size = $main::Folding_length;
    }
    return $word_out;
}

##### HEADER ISO-2022-JP CONVERSION #####
#
# header_iso2022jp_conv(Header)
#	return value: status
#	  0: success
#	 -1: failure
#
sub header_iso2022jp_conv ($$) {
    my ($header, $code_conv) = @_;
    my ($i, $c);
    my ($field_name, $field_value);
    for ($i = 0; $i <= $#$header; $i++) {
	im_debug("Iso2022jp: converting: $$header[$i]\n") if (&debug('encode'));
	$c = &code_check($$header[$i]);
	if ($code_conv) {
	    if ($c eq 'sORe') {
		if ($main::Body_code ne '') {
		    $c = lc($main::Body_code);
		} else {
		    $c = lc($main::Default_code);
		}
	    }
	    im_debug("Iso2022jp: code conversion from $c\n")
		if (&debug('encode'));
	    if ($c eq 'sjis' || $c eq 'euc') {
		$$header[$i] = &conv_iso2022jp($$header[$i], uc($c));
	    }
	    $c = 'jis';
	}
	if ($c eq 'jis') {
	    if ($$header[$i] =~ /^([\w-]+:\s*)(\S.*)/s) {
		$field_name = $1;
		$field_value = $2;
		if ($field_name =~ /^Apparently-To:/i
		 || $field_name =~ /^(Resent-)?(To|Cc|Bcc|Dcc|From|Sender|Reply-To):/i
		 || $field_name =~ /^Originator:/i
		 || $field_name =~ /^Errors-To:/i
		 || $field_name =~ /^Return-Receipt-To:/i) {
		    # structured field
		    my $l = &struct_iso2022jp_mimefy($field_value);
		    return -1 if ($l eq '');
		    $$header[$i] = "$field_name$l";
		} else {
		    $$header[$i] = $field_name.&line_iso2022jp_mimefy($field_value);
		}
	    }
	}
	im_debug("Iso2022jp: converted: $$header[$i]\n")
	  if (&debug('encode'));
    }
    return 0;
}

##### HEADER CONCATINATION #####
#
# hdr_cat(str1, str2, space)
#	str1: a preceeding header string
#	str2: a header string to be appended to str1
#	space: separatig space
#	return value: a concatinated header string
#
sub hdr_cat ($$$) {
    my ($str1, $str2, $space) = @_;

    if ($str1 eq '' || $str1 =~ /\n[\t ]+$/) {
	return "$str1$space$str2";
    }
    $str1 =~ /([^\n]*)$/;
    my $l1 = length($1);
    $str2 =~ /^([^\n]*)/;
    my $l2 = length($1);
    if (!$main::NoFolding
	&& ($l1 + length($space) + $l2 + 1 > $main::Folding_length)) {
	$space = "\t" if ($space eq '');
	return "$str1\n$space$str2";
    }
    return "$str1$space$str2";
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
