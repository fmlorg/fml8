# -*-Perl-*-
################################################################
###
###			      EncDec.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::EncDec.pm version 20000414(IM141)";

package IM::EncDec;
require 5.003;
require Exporter;

use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(mime_encode_string mime_decode_string
		b_encode_string b_decode_string
		q_encode_string q_decode_string);

=head1 NAME

EncDec - MIME header encoder/decoder

=head1 SYNOPSIS

    use IM::EncDec;

    $mime_header_encoded_string =
	mime_encode_string(string, iso7bit, iso8bit);
    $string =
	mime_decode_string(mime_header_encoded_string);

    $B_encoded_string = b_encode_string(string);
    $string = b_decode_string(B_encoded_string);

    $Q_encoded_string = q_encode_string(string);
    $string = q_decode_string(Q_encoded_string);

=head1 DESCRIPTION

MIME header encoder/decoder package.

    $_ = "JAPANESE (Kazuhiko Yamamoto)";
    mime_encode_string($_, 'iso-2022-jp', 'iso-8859-1');
	=> =?iso-2022-jp?B?GyRCOzNLXE9CSScbKEI=?=
		  (Kazuhiko Yamamoto)

    s/\n[\t ]+//g;
    print mime_decode_string($_), "\n";
	=> "JAPANESE (Kazuhiko Yamamoto)"

=cut

use vars qw(@D2H 
	    $mime_encode_switch
	    $mime_decode_switch
	    @Base64a %Base64b
	    @koi_iso);

##################################################
##
## Variables
##

@D2H = ('0'..'9', 'A'..'F');

##################################################
##
## Switches
##

$mime_encode_switch = {
    B => \&b_encode_string,
    Q => \&q_encode_string,
};

$mime_decode_switch = {
    B => \&b_decode_string,
    Q => \&q_decode_string,
};

##################################################
##
## String Encoder/Decoder
##

sub mime_encode_string ($$$) {
    my($str, $iso7, $iso8) = (@_);
    my($point, $len, $nstr, $s) = (0, length($str), '', '');
    my($single, $double) = ('', '');
    my($in) = (0);

    while ($point < $len) {
	$s = substr($str, $point, 1);
	$point ++;
	if ($s eq chr(27)) {
	    if ($nstr ne '') {
		$nstr = $nstr . "\t";
	    }
	    if ($in == 0) {
		# IN
		$in = 1;
		if ($single ne '') {
		    if ($single =~ /[\x00-\x1f\x80-\xff]/) {
			$single = &q_encode_string($single);
			$nstr = $nstr . '=?' . $iso8 . '?Q?' . $single . "?=\n";
		    } else {
			$nstr = $nstr . $single. "\n";
		    }
		    $single = '';
		}
	    } else {
		# OUT
		$in = 0;
		$double = $double . $s . substr($str, $point, 2);
		$point = $point + 2;
		$s = substr($str, $point, 1);
		$point ++;

		$double = &b_encode_string($double);
		$nstr = $nstr . '=?' . $iso7 . '?B?' . $double . '?=';
		$double = '';

		while ($s eq ' ') {
		    $nstr = $nstr . ' ';
		    $s = substr($str, $point, 1);
		    $point ++;
		}
		$nstr = $nstr . "\n";
	    }
	}
	if ($in == 1) {
	    $double = $double . $s;
	} else {
	    $single = $single . $s;
	}
    }
    if ($single ne '') {
	if ($nstr ne '') {
	    $nstr = $nstr . "\t";
	}
	if ($single =~ /[\x00-\x1f\x80-\xff]/) {
	    $single = &q_encode_string($single);
	    $nstr = $nstr . '=?' . $iso8 . '?Q?' . $single . "?=\n";
	} else {
	    $nstr = $nstr . $single. "\n";
	}
    }
    return $nstr;
}

sub mime_decode_string ($) {
    my $in = shift;
    return '' if ($in eq '');
    if (!$main::opt_mimedecodequoted) {
        if ($in =~ /^([^"]*)("[^"]*")([\0-\255]*)$/) {
            return mime_decode_string($1) . $2 . mime_decode_string($3);
	}
    }
    $in =~ s/\?=\s+=\?/?==?/g;
    $in =~ s/(=\?([^?]+)\?(.)\?([^?]+)\?=)/
	($$mime_decode_switch{uc($3)})?mime_decode($2, $3, $4):$1/ge;
    return $in;
}

sub mime_decode($$$) {
    my ($cs, $bq, $str) = @_;
    my $ret = &{$$mime_decode_switch{uc($3)}}($4);
    if ($cs =~ /iso-8859-([2-9])/i) {
	$ret = iso_8859_to_ctext($ret, $1);
    } elsif ($cs =~ /koi8-r/i) {
	$ret = koi8r_to_ctext($ret);
    } elsif ($cs =~ /tis-620/i) {
	$ret = tis_620_to_ctext($ret);
    } elsif ($cs =~ /cn-gb/i || $cs =~ /gb2312/i) {
	$ret = cn_gb_to_ctext($ret);
    } elsif ($cs =~ /hz-gb-2312/i) {
	$ret = hz_to_ctext($ret);
    } elsif ($cs =~ /euc-jp/i) {
	$ret = euc_jp_to_ctext($ret);
    } elsif ($cs =~ /euc-kr/i) {
	$ret = euc_kr_to_ctext($ret);
    } elsif ($cs =~ /shift_jis/i) {
	$ret = shift_jis_to_ctext($ret);
    } elsif ($cs =~ /big5/i || $cs =~ /cn-big5/i) {
	$ret = big5_to_ctext($ret);
    }
    return $ret;
}

sub iso_8859_to_ctext ($$) {
    my ($str, $num) = @_;
    my @index = ("A", "A", "B", "C", "D", "L", "G", "F", "H", "M");
    $str =~ s/([\x80-\xff]+)/\e-$index[$num]$1\e-A/g;
    return $str;
}

@koi_iso =
    (" ", " ", " ", " ", " ", " ", " ", " ", 
     " ", " ", " ", " ", " ", " ", " ", " ", 
     " ", " ", " ", " ", " ", " ", " ", " ", 
     " ", " ", " ", " ", " ", " ", " ", " ", 
     " ", " ", " ", "\xf1", " ", " ", " ", " ", 
     " ", " ", " ", " ", " ", " ", " ", " ", 
     " ", " ", " ", "\xa1", " ", " ", " ", " ", 
     " ", " ", " ", " ", " ", " ", " ", " ", 
     "\xee", "\xd0", "\xd1", "\xe6", "\xd4", "\xd5", "\xe4", "\xd3",
     "\xe5", "\xd8", "\xd9", "\xda", "\xdb", "\\", "\xdd", "\xde",
     "\xdf", "\xef", "\xe0", "\xe1", "\xe2", "\xe3", "\xd6", "\xd2",
     "\xec", "\xeb", "\xd7", "\xe8", "\xed", "\xe9", "\xe7", "\xea",
     "\xce", "\xb0", "\xb1", "\xc6", "\xb4", "\xb5", "\xc4", "\xb3",
     "\xc5", "\xb8", "\xb9", "\xba", "\xbb", "\xbc", "\xbd", "\xbe",
     "\xbf", "\xcf", "\xc0", "\xc1", "\xc2", "\xc3", "\xb6", "\xb2",
     "\xcc", "\xcb", "\xb7", "\xc8", "\xcd", "\xc9", "\xc7", "\xca" );

sub koi2iso ($) {
    my $str = shift;
    $str =~ s/(.)/$koi_iso[ord($1)-128]/ge;
    return $str;
}

sub koi8r_to_ctext($) {
    my $str = shift;
    $str =~ s/([\x80-\xff]+)/"\e-L" . koi2iso($1). "\e-A"/ge;
    return $str;
}

sub tis_620_to_ctext($) {
    my ($str) = shift;
    $str =~ s/([\x80-\xff]+)/\e-T$1\e-A/g;
    return $str;
}

sub cn_gb_to_ctext ($) {
    my $str = shift;
    $str =~ s/([\x80-\xff]+)/"\e\$(A" . remove_msb($1) . "\e(B"/ge;
    return $str;
}

sub hz_to_ctext($) {
    my $str = shift;
    $str =~ s/(~~)/~/g;
    $str =~ s/(~{)/\e\$(A/g;
    $str =~ s/(~})/\e(B/g;
    return $str;
}

sub euc_jp_to_ctext ($) {
    my $str = shift;
    $str =~ s/((\x8f[\xa0-\xff][\xa0-\xff])+)/"\e\$(D"
	. remove_msb(remove_ss($1, "\x8f")) . "\e-A"/ge;
    $str =~ s/(([\xa0-\xff][\xa0-\xff])+)/"\e\$(B"
	. remove_msb($1) . "\e(B"/ge;
    $str =~ s/((\x8e[\x80-\xff])+)/"\e)I" . remove_ss($1, "\x8e") . "\e-A"/ge;
    return $str;
}

sub euc_kr_to_ctext ($) {
    my $str = shift;
    $str =~ s/([\x80-\xff]+)/"\e\$(C" . remove_msb($1) . "\e(B"/ge;
    return $str;
}

sub remove_msb ($) {
    my $str = shift;
    $str =~ tr/\x80-\xff/\x00-\x7f/;
    return $str;
}

sub remove_ss ($$) {
    my ($str, $si) = @_;
    $str =~ s/$si//g;
    return $str;
}

sub shift_jis_to_ctext ($) {
    my $str = shift;
    my $kanji = "[\x81-\x9f\xe0-\xef].";
    my $kana = "[\xa0-\xdf]";

    $str =~ s/($kanji($kanji|$kana)*$kanji|($kanji)+)/\e\$\(B$1\e\(B/g;
    $str =~ s/(($kanji)+)/s2j($1)/ge;
    $str =~ s/(($kana)+)/\e\)I$1\e-A/g;
    return $str;
}

sub s2j($) {
    my $str = shift;
    my ($c1, $c2);
    my $ret = "";

    while ($str) {
	($c1, $c2, $str) = unpack('CCa*', $str);
	if ($c2 >= 0x9f) {
	    $c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe0 : 0x60);
	    $c2 += 2;
	} else {
	    $c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe1 : 0x61);
	    $c2 += 0x60 + ($c2 < 0x7f);
	}
	$c1 &= 0x7f;
	$c2 &= 0x7f;
	$ret .= pack('CC', $c1, $c2);
    }
    return $ret;
}

sub b157to94 ($) {
    my $str = shift;
    my ($c1, $c2, $tmp);
    my $ret = "";

    while ($str) {
	($c1, $c2, $str) = unpack('CCa*', $str);
	if ($c1 < 0xc9) {
	    $tmp = ($c1 - 0xa1) * 157 + $c2;
	} else {
	    $tmp = ($c1 - 0xc9) * 157 + $c2;
	}
	if ($c2 < 0x7f) {
	    $tmp -= 0x40;
	} else {
	    $tmp -= 0x62;
	}
	$c1 = $tmp / 94 + 0x21;
	$c2 = $tmp % 94 + 0x21;
	$ret .= pack('CC', $c1, $c2);	
    }
    return $ret;
}

sub big5_to_ctext($) {
    my $str = shift;

    $str =~ s/([\xa1-\xc6][\x40-\x7e\xa1-\xfe])/"\e\$(0" . 
	b157to94($1) . "\e(B"/ge;
    $str =~ s/([\xc9-\xf9][\x40-\x7e\xa1-\xfe])/"\e\$(1" . 
	b157to94($1) . "\e(B"/ge;
    return $str;
}

##################################################
##
## B Encoder/Decoder
##

sub b_encode_string ($) {
    my $mod3 = length($_[0]) % 3;
    local($_);

    $_ = pack('u', $_[0]);
    chop;
    s/(^|\n).//mg;
    tr[`!-_][A-Za-z0-9+/];

    if    ($mod3 == 1) { s/..$/==/; }
    elsif ($mod3 == 2) { s/.$/=/; }

    $_;
}

sub b_decode_string ($) {
    my $s64 = shift;
    my $len;
    my $res = '';
    local($_);

    while ($s64 =~ s/^(.{1,60})//) {
	$_ = $1;

	$len = length($_) * 3 / 4;
	if (/(=+)$/) {
	    $len -= length($1);
	}
	tr[A-Za-z0-9+/=][`!-_A];

	$res .= sprintf("%c%s\n", $len + 32, $_);
    }
    unpack('u', $res);
}

##################################################
##
## Q Encoder/Decoder
##

sub q_encode_string ($;$) {
    my($line, $struct) = @_;
    local($_);

    $_ = $line;
    if (defined($struct) && $struct) {
	s/([^\w\d\!\*\+\-\/ ])/sprintf("=%02X", unpack('C', $1))/ge;
    } else {
	s/([^\!-<>\@-\^\`-\~ ])/sprintf("=%02X", unpack('C', $1))/ge;
    }
    s/ /_/g;
    $_;
}

sub q_decode_string ($) {
    my($qstr) = @_;
    local($_);

    $_ = $qstr;
    s/_/ /g;
    s/(=)([0-9A-Za-z][0-9A-Za-z])/chr(hex('0x'. $2))/ge;
    $_;
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
