#!/usr/bin/env perl -w

# Copyright (C) 2003 Hajimu UMEMOTO <ume@mahoroba.org>.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the project nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# $Id$

use strict;
use Test;
eval 'use Socket qw(AF_INET AF_INET6 SOCK_STREAM)';
if ($@) {
    use Socket qw(AF_INET SOCK_STREAM);
}
BEGIN { plan tests => 9 }

use Socket6; ok(1);
my @tmp = getaddrinfo("localhost", "", AF_INET, SOCK_STREAM, 0, 0);
if ($#tmp >= 1) {
    ok(2);
}
my($family, $socktype, $protocol, $sin, $canonname) = splice(@tmp, $[, 5);
my($addr, $port) = getnameinfo($sin, NI_NUMERICHOST | NI_NUMERICSERV);
if ($addr eq "127.0.0.1" && $port eq "0") {
    ok(3);
}

my $af_inet6 = eval('AF_INET6');
my $unless_inet6 = !defined($af_inet6) ? 'Skip if not defined AF_INET6' : '';

skip($unless_inet6,
     sub { inet_ntop($af_inet6, inet_pton($af_inet6, "::")), "::" });

# this fails under darwin
skip($unless_inet6,
     sub { inet_ntop($af_inet6, inet_pton($af_inet6, "::21")), "::21" })
    or print "# ", unpack("H*", inet_pton($af_inet6, "::21")), "\n";

skip($unless_inet6,
     sub { inet_ntop($af_inet6, inet_pton($af_inet6, "43::")), "43::" });
skip($unless_inet6,
     sub { inet_ntop($af_inet6, inet_pton($af_inet6, "1:2:3:4:5:6:7::")),
	   "1:2:3:4:5:6:7:0" });
skip($unless_inet6,
     sub { inet_ntop($af_inet6, inet_pton($af_inet6, "1::8")), "1::8" });
skip($unless_inet6,
     sub { inet_ntop($af_inet6, inet_pton($af_inet6, "FF00::FFFF")),
	   "ff00::ffff" });
