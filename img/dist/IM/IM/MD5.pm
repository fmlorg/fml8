# -*-Perl-*-
################################################################
###
###				MD5.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Mar 22, 2003
###

my $PM_VERSION = "IM::MD5.pm version 20030322(IM144)";

package IM::MD5;
require 5.003;
require Exporter;

#no integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(md5_str);

use vars qw($MD5_S11 $MD5_S12 $MD5_S13 $MD5_S14
	    $MD5_S21 $MD5_S22 $MD5_S23 $MD5_S24
	    $MD5_S31 $MD5_S32 $MD5_S33 $MD5_S34
	    $MD5_S41 $MD5_S42 $MD5_S43 $MD5_S44
	    @MD5_PADDING);
################
# MD5 routines #
################

sub md5_str($) {
    my($str) = @_;
    my($len);
    my(@context_count, @context_state, @context_buffer);
    my(@digest);

    $len = length($str);
    my @string = unpack('C*', $str);

    &MD5Init(\@context_count, \@context_state, \@context_buffer);
    &MD5Update(\@context_count, \@context_state, \@context_buffer, 
	       \@string, $len);
    &MD5Final(\@digest, \@context_count, \@context_state, \@context_buffer);

    return unpack('H*', pack('C*', @digest));
}

###############################################################################

# F, G, H and I are basic MD5 functions.

sub MD5_F {my($x, $y, $z) = @_; ((($x) & ($y)) | (&MD5_trunc(~$x) & ($z))); }
sub MD5_G {my($x, $y, $z) = @_; ((($x) & ($z)) | (($y) & &MD5_trunc(~$z))); }
sub MD5_H {my($x, $y, $z) = @_; (($x) ^ ($y) ^ ($z)); }
sub MD5_I {my($x, $y, $z) = @_; (($y) ^ (($x) | &MD5_trunc(~$z))); }

# ROTATE_LEFT rotates x left n bits.

sub MD5_ROTATE_LEFT {
    my($x, $n) = @_;
    if ($n != 0) {
    $x = (($x & (0x7fffffff >> ($n-1))) << $n)
       | (($x >> (32-$n)) & (0x7fffffff >> (31-$n)));
    }
    return $x;
}

# FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
# Rotation is separate from addition to prevent recomputation.

sub MD5_FF {
    my($a, $b, $c, $d, $x, $s, $ac) = @_;
    $a = &MD5_trunc($a + &MD5_F($b, $c, $d) + $x + $ac);
    $a = &MD5_ROTATE_LEFT($a, $s);
    $a = &MD5_trunc($a + $b);
}
sub MD5_GG {
    my($a, $b, $c, $d, $x, $s, $ac) = @_;
    $a = &MD5_trunc($a + &MD5_G($b, $c, $d) + $x + $ac);
    $a = &MD5_ROTATE_LEFT($a, $s);
    $a = &MD5_trunc($a + $b);
}
sub MD5_HH {
    my($a, $b, $c, $d, $x, $s, $ac) = @_;
    $a = &MD5_trunc($a + &MD5_H($b, $c, $d) + $x + $ac);
    $a = &MD5_ROTATE_LEFT($a, $s);
    $a = &MD5_trunc($a + $b);
}
sub MD5_II {
    my($a, $b, $c, $d, $x, $s, $ac) = @_;
    $a = &MD5_trunc($a + &MD5_I($b, $c, $d) + $x + $ac);
    $a = &MD5_ROTATE_LEFT($a, $s);
    $a = &MD5_trunc($a + $b);
    return $a;
}

# Truncate to 32bits-wide integer

sub MD5_trunc {
    my($x) = @_;

    if (($x | 0) == $x) {
	$x &= 0xffffffff;
    } else {
	while ($x >= 4294967296) {
	    $x -= 4294967296;
	}
    }
    return $x;
}

# MD5 initialization. Begins an MD5 operation, writing a new context.

sub MD5Init($$$) {
    my($context_count, $context_state, $context_buffer) = @_;

    # Constants for MD5Transform routine.
    $MD5_S11 = 7;
    $MD5_S12 = 12;
    $MD5_S13 = 17;
    $MD5_S14 = 22;
    $MD5_S21 = 5;
    $MD5_S22 = 9;
    $MD5_S23 = 14;
    $MD5_S24 = 20;
    $MD5_S31 = 4;
    $MD5_S32 = 11;
    $MD5_S33 = 16;
    $MD5_S34 = 23;
    $MD5_S41 = 6;
    $MD5_S42 = 10;
    $MD5_S43 = 15;
    $MD5_S44 = 21;

    @MD5_PADDING = (
	0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

    $context_count->[0] = $context_count->[1] = 0;
    # Load magic initialization constants.
    $context_state->[0] = 0x67452301;
    $context_state->[1] = 0xefcdab89;
    $context_state->[2] = 0x98badcfe;
    $context_state->[3] = 0x10325476;
    @{$context_buffer} = ((0) x 64);
}

# MD5 block update operation. Continues an MD5 message-digest
# operation, processing another message block, and updating the
# context.

sub MD5Update($$$$$) {
    my($context_count, $context_state, $context_buffer,
	$input, $inputLen) = @_;
    my(@arg1, @arg2);
    my($i, $index, $partLen);

    # Compute number of bytes mod 64
    $index = (($context_count->[0] >> 3) & 0x3F);

    # Update number of bits
    if (($context_count->[0] += ($inputLen << 3)) < ($inputLen << 3)) {
	$context_count->[1]++;
    }
    $context_count->[1] += ($inputLen >> 29);

    $partLen = 64 - $index;

    # Transform as many times as possible.

    if ($inputLen >= $partLen) {
	@arg1 = @{$context_buffer}[$index .. $#{$context_buffer}];
	&MD5_memcpy(\@arg1, $input, $partLen);
	splice(@{$context_buffer}, $index, $#arg1, @arg1);
	&MD5Transform($context_state, $context_buffer);

	for ($i = $partLen; $i + 63 < $inputLen; $i += 64) {
	    @arg2 = $input->[$i .. $#{$input}];
	    &MD5Transform($context_state, \@arg2);
	}

	$index = 0;
    }
    else
    {
	$i = 0;
    }

    # Buffer remaining input
    @arg1 = @{$context_buffer}[$index .. $#{$context_buffer}];
    @arg2 = @{$input}[$i .. $#{$input}];
    &MD5_memcpy(\@arg1, \@arg2, $inputLen-$i);
    splice(@{$context_buffer}, $index, $#arg1, @arg1);
}

# MD5 finalization. Ends an MD5 message-digest operation, writing the
# the message digest and zeroizing the context.

sub MD5Final($$$$) {
    my($digest, $context_count, $context_state, $context_buffer) = @_;
    my(@bits);
    my($index, $padLen);
    @bits = ((0) x 8);

    # Save number of bits
    &MD5_Encode(\@bits, $context_count, 8);

    # Pad out to 56 mod 64.
    $index = (($context_count->[0] >> 3) & 0x3f);
    $padLen = ($index < 56) ? (56 - $index) : (120 - $index);
    &MD5Update($context_count, $context_state, $context_buffer,
	       \@MD5_PADDING, $padLen);

    # Append length (before padding)
    &MD5Update($context_count, $context_state, $context_buffer, \@bits, 8);

    # Store state in digest
    &MD5_Encode($digest, $context_state, 16);

    # Zeroize sensitive information.
    &MD5_memset($context_state, 0, 4);
    &MD5_memset($context_count, 0, 2);
    &MD5_memset($context_buffer, 0, 64);
}

# MD5 basic transformation. Transforms state based on block.

sub MD5Transform($$) {
    my($state, $block) = @_;
    my($a) = $state->[0];
    my($b) = $state->[1];
    my($c) = $state->[2];
    my($d) = $state->[3];
    my(@x);

    &MD5_Decode(\@x, $block, 64);

    # Round 1
    $a = &MD5_FF($a, $b, $c, $d, $x[ 0], $MD5_S11, 0xd76aa478); #  1
    $d = &MD5_FF($d, $a, $b, $c, $x[ 1], $MD5_S12, 0xe8c7b756); #  2
    $c = &MD5_FF($c, $d, $a, $b, $x[ 2], $MD5_S13, 0x242070db); #  3
    $b = &MD5_FF($b, $c, $d, $a, $x[ 3], $MD5_S14, 0xc1bdceee); #  4
    $a = &MD5_FF($a, $b, $c, $d, $x[ 4], $MD5_S11, 0xf57c0faf); #  5
    $d = &MD5_FF($d, $a, $b, $c, $x[ 5], $MD5_S12, 0x4787c62a); #  6
    $c = &MD5_FF($c, $d, $a, $b, $x[ 6], $MD5_S13, 0xa8304613); #  7
    $b = &MD5_FF($b, $c, $d, $a, $x[ 7], $MD5_S14, 0xfd469501); #  8
    $a = &MD5_FF($a, $b, $c, $d, $x[ 8], $MD5_S11, 0x698098d8); #  9
    $d = &MD5_FF($d, $a, $b, $c, $x[ 9], $MD5_S12, 0x8b44f7af); # 10
    $c = &MD5_FF($c, $d, $a, $b, $x[10], $MD5_S13, 0xffff5bb1); # 11
    $b = &MD5_FF($b, $c, $d, $a, $x[11], $MD5_S14, 0x895cd7be); # 12
    $a = &MD5_FF($a, $b, $c, $d, $x[12], $MD5_S11, 0x6b901122); # 13
    $d = &MD5_FF($d, $a, $b, $c, $x[13], $MD5_S12, 0xfd987193); # 14
    $c = &MD5_FF($c, $d, $a, $b, $x[14], $MD5_S13, 0xa679438e); # 15
    $b = &MD5_FF($b, $c, $d, $a, $x[15], $MD5_S14, 0x49b40821); # 16

    # Round 2
    $a = &MD5_GG($a, $b, $c, $d, $x[ 1], $MD5_S21, 0xf61e2562); # 17
    $d = &MD5_GG($d, $a, $b, $c, $x[ 6], $MD5_S22, 0xc040b340); # 18
    $c = &MD5_GG($c, $d, $a, $b, $x[11], $MD5_S23, 0x265e5a51); # 19
    $b = &MD5_GG($b, $c, $d, $a, $x[ 0], $MD5_S24, 0xe9b6c7aa); # 20
    $a = &MD5_GG($a, $b, $c, $d, $x[ 5], $MD5_S21, 0xd62f105d); # 21
    $d = &MD5_GG($d, $a, $b, $c, $x[10], $MD5_S22,  0x2441453); # 22
    $c = &MD5_GG($c, $d, $a, $b, $x[15], $MD5_S23, 0xd8a1e681); # 23
    $b = &MD5_GG($b, $c, $d, $a, $x[ 4], $MD5_S24, 0xe7d3fbc8); # 24
    $a = &MD5_GG($a, $b, $c, $d, $x[ 9], $MD5_S21, 0x21e1cde6); # 25
    $d = &MD5_GG($d, $a, $b, $c, $x[14], $MD5_S22, 0xc33707d6); # 26
    $c = &MD5_GG($c, $d, $a, $b, $x[ 3], $MD5_S23, 0xf4d50d87); # 27
    $b = &MD5_GG($b, $c, $d, $a, $x[ 8], $MD5_S24, 0x455a14ed); # 28
    $a = &MD5_GG($a, $b, $c, $d, $x[13], $MD5_S21, 0xa9e3e905); # 29
    $d = &MD5_GG($d, $a, $b, $c, $x[ 2], $MD5_S22, 0xfcefa3f8); # 30
    $c = &MD5_GG($c, $d, $a, $b, $x[ 7], $MD5_S23, 0x676f02d9); # 31
    $b = &MD5_GG($b, $c, $d, $a, $x[12], $MD5_S24, 0x8d2a4c8a); # 32

    # Round 3
    $a = &MD5_HH($a, $b, $c, $d, $x[ 5], $MD5_S31, 0xfffa3942); # 33
    $d = &MD5_HH($d, $a, $b, $c, $x[ 8], $MD5_S32, 0x8771f681); # 34
    $c = &MD5_HH($c, $d, $a, $b, $x[11], $MD5_S33, 0x6d9d6122); # 35
    $b = &MD5_HH($b, $c, $d, $a, $x[14], $MD5_S34, 0xfde5380c); # 36
    $a = &MD5_HH($a, $b, $c, $d, $x[ 1], $MD5_S31, 0xa4beea44); # 37
    $d = &MD5_HH($d, $a, $b, $c, $x[ 4], $MD5_S32, 0x4bdecfa9); # 38
    $c = &MD5_HH($c, $d, $a, $b, $x[ 7], $MD5_S33, 0xf6bb4b60); # 39
    $b = &MD5_HH($b, $c, $d, $a, $x[10], $MD5_S34, 0xbebfbc70); # 40
    $a = &MD5_HH($a, $b, $c, $d, $x[13], $MD5_S31, 0x289b7ec6); # 41
    $d = &MD5_HH($d, $a, $b, $c, $x[ 0], $MD5_S32, 0xeaa127fa); # 42
    $c = &MD5_HH($c, $d, $a, $b, $x[ 3], $MD5_S33, 0xd4ef3085); # 43
    $b = &MD5_HH($b, $c, $d, $a, $x[ 6], $MD5_S34,  0x4881d05); # 44
    $a = &MD5_HH($a, $b, $c, $d, $x[ 9], $MD5_S31, 0xd9d4d039); # 45
    $d = &MD5_HH($d, $a, $b, $c, $x[12], $MD5_S32, 0xe6db99e5); # 46
    $c = &MD5_HH($c, $d, $a, $b, $x[15], $MD5_S33, 0x1fa27cf8); # 47
    $b = &MD5_HH($b, $c, $d, $a, $x[ 2], $MD5_S34, 0xc4ac5665); # 48

    # Round 4
    $a = &MD5_II($a, $b, $c, $d, $x[ 0], $MD5_S41, 0xf4292244); # 49
    $d = &MD5_II($d, $a, $b, $c, $x[ 7], $MD5_S42, 0x432aff97); # 50
    $c = &MD5_II($c, $d, $a, $b, $x[14], $MD5_S43, 0xab9423a7); # 51
    $b = &MD5_II($b, $c, $d, $a, $x[ 5], $MD5_S44, 0xfc93a039); # 52
    $a = &MD5_II($a, $b, $c, $d, $x[12], $MD5_S41, 0x655b59c3); # 53
    $d = &MD5_II($d, $a, $b, $c, $x[ 3], $MD5_S42, 0x8f0ccc92); # 54
    $c = &MD5_II($c, $d, $a, $b, $x[10], $MD5_S43, 0xffeff47d); # 55
    $b = &MD5_II($b, $c, $d, $a, $x[ 1], $MD5_S44, 0x85845dd1); # 56
    $a = &MD5_II($a, $b, $c, $d, $x[ 8], $MD5_S41, 0x6fa87e4f); # 57
    $d = &MD5_II($d, $a, $b, $c, $x[15], $MD5_S42, 0xfe2ce6e0); # 58
    $c = &MD5_II($c, $d, $a, $b, $x[ 6], $MD5_S43, 0xa3014314); # 59
    $b = &MD5_II($b, $c, $d, $a, $x[13], $MD5_S44, 0x4e0811a1); # 60
    $a = &MD5_II($a, $b, $c, $d, $x[ 4], $MD5_S41, 0xf7537e82); # 61
    $d = &MD5_II($d, $a, $b, $c, $x[11], $MD5_S42, 0xbd3af235); # 62
    $c = &MD5_II($c, $d, $a, $b, $x[ 2], $MD5_S43, 0x2ad7d2bb); # 63
    $b = &MD5_II($b, $c, $d, $a, $x[ 9], $MD5_S44, 0xeb86d391); # 64

    $state->[0] = &MD5_trunc($state->[0] + $a);
    $state->[1] = &MD5_trunc($state->[1] + $b);
    $state->[2] = &MD5_trunc($state->[2] + $c);
    $state->[3] = &MD5_trunc($state->[3] + $d);

    # Zeroize sensitive information.
    &MD5_memset(\@x, 0, 64);
}

# Encodes input (UINT4) into output (unsigned char). Assumes len is
# a multiple of 4.

sub MD5_Encode($$$) {
    my($output, $input, $len) = @_;
    my($i, $j);

    for ($i = 0, $j = 0; $j < $len; $i++, $j += 4) {
	$output->[$j]   =  ($input->[$i] & 0xff);
	$output->[$j+1] = (($input->[$i] >> 8) & 0xff);
	$output->[$j+2] = (($input->[$i] >> 16) & 0xff);
	$output->[$j+3] = (($input->[$i] >> 24) & 0xff);
    }
}

# Decodes input (unsigned char) into output (UINT4). Assumes len is
# a multiple of 4.

sub MD5_Decode($$$) {
    my($output, $input, my $len) = @_;
    my($i, $j);

    for ($i = 0, $j = 0; $j < $len; $i++, $j += 4) {
	$output->[$i] = ($input->[$j]) | (($input->[$j+1]) << 8) |
	  (($input->[$j+2]) << 16) | (($input->[$j+3]) << 24);
    }
}

# Note: Replace "for loop" with standard memcpy if possible.

sub MD5_memcpy($$$) {
    my($output, $input, $len) = @_;
    my($i);

    for ($i = 0; $i < $len; $i++) {
	$output->[$i] = $input->[$i];
    }
}

# Note: Replace "for loop" with standard memset if possible.

sub MD5_memset($$$) {
    my($output, $value, $len) = @_;
    my($i);

    for ($i = 0; $i < $len; $i++) {
	$output->[$i] = $value;
    }
}

use SelfLoader;
1;
__DATA__

sub MD5_CHECK {
    my($str, $should) = @_;
    my($r) = &md5_str($str);

    printf "MD5 (\"%s\") = %s", $str, $r;
    if ($r eq $should) {
	print ", ok\n";
    } else {
	print ", ERROR should be $should\n";
    }
}

sub MD5_TEST {
    my(%v);
    $v{""} = "d41d8cd98f00b204e9800998ecf8427e";
    $v{"a"} = "0cc175b9c0f1b6a831c399e269772661";
    $v{"abc"} = "900150983cd24fb0d6963f7d28e17f72";
    $v{"message digest"} = "f96b697d7cb7938d525a2f31aaf161d0";
    $v{"abcdefghijklmnopqrstuvwxyz"} = "c3fcd3d76192e4007dfb496cca67e13b";
    $v{"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"} = "d174ab98d277d9f5a5611c2c9f419d9f";
    $v{"12345678901234567890123456789012345678901234567890123456789012345678901234567890"} = "57edf4a22be3c955ac49da2e2107b67a";

    print "MD5 test suite:\n";
    foreach (keys %v) {
	&MD5_CHECK($_, $v{$_});
    }
}

1;

__END__

=head1 NAME

IM::MD5 - MD5 message-digesting

=head1 SYNOPSIS

 use IM::MD5;

 $digest = &md5_str($text);

=head1 DESCRIPTION

The I<IM::MD5> module handles MD5 message-digest algorithm.

This modules is provided by IM (Internet Message).

=head1 EXAMPLES

 &md5_str("") returns d41d8cd98f00b204e9800998ecf8427e.
 &md5_str("a") returns 0cc175b9c0f1b6a831c399e269772661.
 &md5_str("abc") returns 900150983cd24fb0d6963f7d28e17f72.
 &md5_str("message digest") returns f96b697d7cb7938d525a2f31aaf161d0.
 &md5_str("abcdefghijklmnopqrstuvwxyz") returns c3fcd3d76192e4007dfb496cca67e13b.
 &md5_str("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") returns d174ab98d277d9f5a5611c2c9f419d9f.
 &md5_str("12345678901234567890123456789012345678901234567890123456789012345678901234567890") returns 57edf4a22be3c955ac49da2e2107b67a.

 % perl -MIM::MD5 -e 'IM::MD5::MD5_TEST()'

=head1 COPYRIGHT

This modules is derived from md5.pl copyrighted by NAKAMURA, Motonori
<motonori@econ.kyoto-u.ac.jp>.  It is converted to Perl4 from C version
derived from the RSA Data Security, Inc. MD5 Message-Digest Algorithm.

IM (Internet Message) is copyrighted by IM developing team.
You can redistribute it and/or modify it under the modified BSD
license.  See the copyright file for more details.

=cut

###  md5.pl -- MD5 message-digest algorithm converted to Perl4 from C version
###
###  Copyright (C) 1996 by NAKAMURA, Motonori <motonori@econ.kyoto-u.ac.jp>.
###  All rights reserved.
###  [August 16, 1996]
### 
###    MD5C.C - RSA Data Security, Inc., MD5 message-digest algorithm
### 
### Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
### rights reserved.
### 
### License to copy and use this software is granted provided that it
### is identified as the "RSA Data Security, Inc. MD5 Message-Digest
### Algorithm" in all material mentioning or referencing this software
### or this function.
### 
### License is also granted to make and use derivative works provided
### that such works are identified as "derived from the RSA Data
### Security, Inc. MD5 Message-Digest Algorithm" in all material
### mentioning or referencing the derived work.
### 
### RSA Data Security, Inc. makes no representations concerning either
### the merchantability of this software or the suitability of this
### software for any particular purpose. It is provided "as is"
### without express or implied warranty of any kind.
### 
### These notices must be retained in any copies of any part of this
### documentation and/or software.

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
