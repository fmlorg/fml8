# -*-Perl-*-
################################################################
###
###			     Japanese.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Jun  1, 2003
###

my $PM_VERSION = "IM::Japanese.pm version 20030601(IM145)";

package IM::Japanese;
require 5.003;
require Exporter;

use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(code_check code_check_body
	     convert_iso2022jp_body conv_iso2022jp
	     conv_euc_from_jis conv_euc_from_sjis);

use vars qw($C_jis $C_jis_roman $C_sjis $C_sjis_kana
	    $C_euc $C_euc_kana $C_SorE $C_ascii
	    $C_pascii $C_tascii $C_sascii $C_8bit
	    $E_jp $E_asc $E_kana);
BEGIN {
    $C_jis       = '(\e\$[\@B])([\x21-\x7e]+)';
    $C_jis_roman = '(\e\([BJ])([\s\x21-\x7e]*)';
    $C_sjis      = '[\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]';
    $C_sjis_kana = '[\xa1-\xdf]';
    $C_euc       = '[\xa1-\xfe][\xa1-\xfe]';
    $C_euc_kana  = '\x8e[\xa1-\xdf]';
    $C_SorE      = '[\xa1-\xdf]|[\x8e\xe0-\xfc][\xa1-\xfc]';
    $C_ascii     = '[\s\x21-\x7e]';
#   $C_ascii     = '[\x07\s\x21-\x7e]';	# for IRC freak :-)
    $C_pascii    = '[\x21-\x7e]';
    $C_tascii    = '[\x21\x23-\x27\x2a\x2b\x2d\x30-\x39\x41-\x5a\x5e-\x7e]';
    $C_sascii    = '[\x22\x28\x29\x2c\x2e\x2f\x3a-\x40\x5b-\x5d]';

    $C_8bit      = '[\x80-\xff]';

    ($E_jp, $E_asc, $E_kana) = ("\e\$B", "\e(B", "\e(I");
}

##### CODE CHECKER #####
#
# code_check(line, use_hankaku_kana)
#	line: a line of string to be checked
#	use_hankaku_kana: bool value if check hankaku kana
#	return value: encoding type
#		ascii
#		8bit
#		jis
#		euc
#		sjis
#		sORe
#
sub code_check($;$) {
    my($line, $no_hankaku_kana) = @_;
    my($sjis, $euc);

    if ($line =~ /^$C_ascii*$/o) {
	return 'ascii';
    } elsif ($line =~ /$C_jis/o) {
	return 'jis';
    }

    if ($no_hankaku_kana) {
	$euc = 1 if $line =~ /^($C_ascii|$C_euc)+$/o;
	$sjis = 1 if $line =~ /^($C_ascii|$C_sjis)+$/o;
    } else {
	$euc = 1 if $line =~ /^($C_ascii|$C_euc|$C_euc_kana)+$/o;
	$sjis = 1 if $line =~ /^($C_ascii|$C_sjis|$C_sjis_kana)+$/o;
    }

    if ($euc && $sjis) {
	return 'sORe';
    } elsif ($euc) {
	return 'euc';
    } elsif ($sjis) {
	return 'sjis';
    }
    return '8bit';
}

##### BODY CODE CHECKER #####
#
# code_check_body(content)
#	content: pointer to body content line list
#	return value: encode type
#		ASCII
#		8BIT
#		JIS
#		EUC
#		SJIS
#
sub code_check_body($) {
    my $content = shift;
    my(%count) = ();

    $count{'ascii'} = 0;	# for debug print
    $count{'8bit'} = 0;
    $count{'jis'} = 0;
    $count{'euc'} = 0;
    $count{'sjis'} = 0;
    $count{'sORe'} = 0;
    $count{'has8bit'} = 0;
    $count{'total'} = 0;

    my $i;
    for ($i = 0; $i <= $#$content; $i++) {
	$count{code_check($$content[$i])}++;
	my $line = $$content[$i];
	$count{'total'} += length($line);
	$line =~ s/[^\x80-\xff]//g;
	$count{'has8bit'} += length($line);
    }
    # select encoding
    if ($count{'has8bit'} * 8 > $count{'total'}) {
	$main::Need_base64_encoded = 1;
    } else {
	$main::Need_base64_encoded = 0;
    }
    if (&debug('code')) {
	im_debug("ascii = $count{'ascii'}\n");
	im_debug("8bit = $count{'8bit'}\n");
	im_debug("jis = $count{'jis'}\n");
	im_debug("euc = $count{'euc'}\n");
	im_debug("sjis = $count{'sjis'}\n");
	im_debug("sORe = $count{'sORe'}\n");
    }
    return '8BIT' if ($count{'8bit'});
    if ($count{'jis'}) {
	return '8BIT'
	    if ($count{'sORe'} || $count{'sjis'} || $count{'euc'});
	return 'JIS';
    }
    if ($count{'sjis'}) {
	return '8BIT' if ($count{'euc'});
	return 'SJIS';
    }
    return 'EUC' if ($count{'euc'});
    return uc($main::Default_code) if ($count{'sORe'});
    return 'ASCII';
}

##### CONVERT BODY INTO ISO-2022-JP ENCODING #####
#
# convert_iso2022jp_body(content, code)
#	content: pointer to body content line list
#	code: input kanji code
#	return value: none
#
sub convert_iso2022jp_body($$) {
    my($content, $code) = @_;

    my $i;
    for ($i = 0; $i <= $#$content; $i++) {
	$$content[$i] = conv_iso2022jp($$content[$i], $code);
    }
}

##### ISO-2022-JP CODE CONVERSION #####
#
# conv_iso2022jp(line, code)
#	line: a line of string to be converted
#	code: input kanji code
#	return value: converted line
#
sub conv_iso2022jp($;$) {
    my($line, $code) = @_;

    im_debug("conv_iso2022jp: $line\n") if (&debug('japanese'));

    unless ($line =~ /[\x80-\xff]/) {
	im_debug("source is ascii or jis\n") if (&debug('japanese'));
	return $line;
    }

    if ($code eq 'NoHankana') {
	$code = uc(code_check($line, 1));
    } elsif (!defined($code)) {
	$code = uc(code_check($line));
    }
    $code = uc($main::Default_code) if ($code eq 'SORE');

    if ($code eq 'EUC') {
	im_debug("source is euc\n") if (&debug('japanese'));
	return &conv_from_euc($line);
    } elsif ($code eq 'SJIS') {
	im_debug("source is sjis\n") if (&debug('japanese'));
	return &conv_from_sjis($line);
    }
    im_debug("source is unknown, nothing done\n") if (&debug('japanese'));
    return $line;
}

##### ISO-2022-JP CODE CONVERSION FROM SJIS #####
#
# conv_from_sjis(line)
#	line: a line of string to be converted
#	return value: converted line
#
sub conv_from_sjis($) {
    my $line = shift;
    $line =~ s/((?:$C_sjis|$C_sjis_kana)+)/sjis2jis($1)/geo;
    return $line;
}
sub sjis2jis($) {
    my $line = shift;
    $line =~ s/((?:$C_sjis)+|(?:$C_sjis_kana)+)/s2j($1)/geo;
    return "$line$E_asc";
}
sub s2e($) {
    my $code = shift;
    my($c1, $c2) = unpack('CC', $code);
    if (0xa1 <= $c1 && $c1 <= 0xdf) {
	$c2 = $c1;
	$c1 = 0x8e;
    } elsif ($c2 >= 0x9f) {
	$c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe0 : 0x60);
	$c2 += 2;
    } else {
	$c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe1 : 0x61);
	$c2 += 0x60 + ($c2 < 0x7f);
    }
    return pack('CC', $c1, $c2);
}
sub s2j($) {
    my $cur = shift;
    if ($cur =~ /^$C_sjis_kana/o) {
	$cur =~ tr/\xa1-\xdf/\x21-\x5f/;
	return "$E_kana$cur";
    } else {
	$cur =~ s/(..)/s2e($1)/ge;
	$cur =~ tr/\xa1-\xfe/\x21-\x7e/;
	return "$E_jp$cur";
    }
}

##### ISO-2022-JP CODE CONVERSION FROM EUC #####
#
# conv_from_euc(line)
#	line: a line of string to be converted
#	return value: converted line
#
sub conv_from_euc($) {
    my $line = shift;
    $line =~ s/((?:$C_euc|$C_euc_kana)+)/euc2jis($1)/geo;
    return $line;
}
sub euc2jis($) {
    my $line = shift;
    $line =~ s/((?:$C_euc)+|(?:$C_euc_kana)+)/e2j($1)/geo;
    return "$line$E_asc";
}
sub e2j($) {
    my $cur = shift;
    $cur =~ tr/\xa1-\xfe/\x21-\x7e/;
    if ($cur =~ tr/\x8e//d) {
	return "$E_kana$cur";
    } else {
	return "$E_jp$cur";
    }
}

##### EUC CODE CONVERSION FROM SJIS #####
#
# conv_euc_from_sjis(line)
#	line: a line of string to be converted
#	return value: converted line
#

sub conv_euc_from_sjis($) {
    my $line = shift;
    $line =~ s/($C_sjis|$C_sjis_kana)/s2e($1)/geo;  
    return $line;
}

##### EUC CODE CONVERSION FROM JIS #####
#
# conv_euc_from_jis(line)
#	line: a line of string to be converted
#	return value: converted line
#

sub conv_euc_from_jis($) {
    my $line = shift;
    $line =~ s/$C_jis/j2e($1,$2)/geo;
    $line =~ s/\e\$C_jis_roman/$2/geo;
    return $line;
}

sub j2e($$) {
    my $esc = shift;
    my $line = shift;
    if ($esc =~ /\e\$[\@B]/) {
       $line =~ tr/\x21-\x7e/\xa1-\xfe/;
    }
    return $line;
}

1;

__END__

=head1 NAME

IM::Japanese - Japanese message handler

=head1 SYNOPSIS

 use IM::Japanese;

 $code = code_check($line, $use_hankaku_kana);
 $code = code_check_body($content);
 convert_iso2022jp_body($content, $code);
 $converted = conv_iso2022jp($line, $code);

=head1 DESCRIPTION

The I<IM::Japanese> module handles Japanese message encoded with
ISO-2022-JP, EUC-JP, Shift_JIS, or US-ASCII.

This modules is provided by IM (Internet Message).

=head1 COPYRIGHT

IM (Internet Message) is copyrighted by IM developing team.
You can redistribute it and/or modify it under the modified BSD
license.  See the copyright file for more details.

=cut

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
