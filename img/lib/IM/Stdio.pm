# -*-Perl-*-
################################################################
###
###			       Stdio.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: May 7, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::Stdio.pm version 20000414(IM141)";

package IM::Stdio;
require 5.003;
require Exporter;

use IM::Config;
use integer;
use strict;
use vars qw(@ISA @EXPORT $old); # why not my($old)?

@ISA = qw(Exporter);
@EXPORT = qw(flush);

sub flush (*) {
    local($old) = select(shift);
    $| = 1;
    print '';
    $| = 0;
    select($old);
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
