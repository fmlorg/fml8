# -*-Perl-*-
################################################################
###
###			      Util.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::Util.pm version 20000414(IM141)";

package IM::Util;
require 5.003;
require Exporter;

use integer;
use strict;
use vars qw(@ISA @EXPORT
	    $SUCCESS $ERROR $EXIT_SUCCESS $EXIT_ERROR
	    $old); # why not my($old)?

@ISA = qw(Exporter);
@EXPORT = qw($SUCCESS $ERROR $EXIT_SUCCESS $EXIT_ERROR
	     unixp win95p wntp os2p
	     progname
	     im_getlogin
	     im_msg im_info im_debug im_notice im_warn im_err im_die im_die2
	     im_save_error im_saved_errors im_open im_sysopen
	     debug_option set_debug debug set_verbose verbose
	     flush);

use vars qw($OS $SavedMsg %Debug);

###
### Constant
###

$SUCCESS = 1;
$ERROR = 0;

$EXIT_SUCCESS = 0;
$EXIT_ERROR = 1;

###
### get OS name
###

my $osname = $^O;

if ($osname =~ /win/i) {
    if (Win32::IsWinNT()) {
	$OS = 'WNT';
    } elsif (Win32::IsWin95()) {
	$OS = 'WIN95';
    } else {
	$OS = 'WIN95';		# xxx
    }
} elsif ($osname =~ /os2/i) {
    $OS = 'OS/2';
} else {
    $OS = 'UNIX';
}

sub unixp {
    if ($OS eq 'UNIX') {
	return 1;
    } else {
	return 0;
    }
}

sub win95p {
    if (($OS eq 'WIN95') || ($OS eq 'WNT') ){
	return 1;
    } else {
	return 0;
    }
}

sub wntp {
    if ($OS eq 'WNT') {
	return 1;
    } else {
	return 0;
    }
}

sub os2p {
    if ($OS eq 'OS/2') {
	return 1;
    } else {
	return 0;
    }
}

sub progname () {
    return $main::Prog;
}

###
### get login name
###
sub im_getlogin () {
    if (&unixp()) {
	my $login = getlogin();
	if ($login ne '' && $login ne 'root') {
	    return $login;
	} else {
	    return (getpwuid($<))[0] || undef;
	}
    } elsif (&os2p()){
	return getlogin() || undef;
    } elsif (&win95p()){
	return Win32::LoginName();
    }
}

###
### message
###

# im_msg    - display desired information
# im_debug  - display debugging information (with --debug or something)
# im_info   - display informational messages (hidden with --quiet)
# im_notice - display process tracing information (shown with --verbose)
# im_warn   - display problem report -- the problem may be ignored
# im_err    - display critical error messages -- process will be aborted
# im_die    - display critical error messages and exit

sub im_msg ($) {
    my $msg = shift;
    print progname(), ': ', $msg;
}

sub im_info ($) {
    my $info = shift;
    return if $main::opt_quiet;
    print progname(), ': ', $info;
}

sub im_debug ($) {
    my $dbg = shift;
    print STDERR progname(), ':DEBUG: ', $dbg;
}

sub im_notice ($) {
    return unless &verbose;
    my $warn = progname() . ': '. shift;
    $SavedMsg .= $warn;
    print STDERR $warn;
}

sub im_warn ($) {
    my $warn = progname() . ': '. shift;
    $SavedMsg .= $warn;
    print STDERR $warn;
}

sub im_err ($) {
    my $err = progname() . ': ERROR: ' . shift;
    $SavedMsg .= $err;
    print STDERR $err;
}

sub im_die ($) {
    my $die = shift;
    print STDERR progname(), ': ERROR: ', $die;
    exit $EXIT_ERROR;
}

sub im_die2 ($) {
    my $die = shift;
    print STDERR progname(), ': ', $die;
    exit $EXIT_ERROR;
}

sub im_save_error (;$) {
    my $string = shift;
    if ($string eq '') {
	$SavedMsg = '';	# reset
    } else {
	$SavedMsg .= $string;
    }
}

sub im_saved_errors () {
    return $SavedMsg;
}

###
### Debug
###

sub print_hash (\%)
{
    my $hashref = shift;

    foreach (keys(%{$hashref})){
	print "$_ -> $hashref->{$_}\n";
    }
}

sub set_debug ($$) {
    my $category = shift;

    $Debug{$category} = shift;
}

sub debug ($) {
    my $category = shift;

    if ($Debug{'all'}) {
	return $Debug{'all'};
    } else {
	return $Debug{$category};
    }
}

sub set_verbose ($) {
    $main::opt_verbose = shift;
}

sub verbose () {
    return $main::opt_verbose;
}

##### SET DEBUG OPTION #####
#
# debug_option()
#
sub debug_option ($) {
    my $DebugFlag = shift;

    if ($DebugFlag && ($DebugFlag !~ /^(off|no|false|0)$/)) {
	foreach (split(',', $DebugFlag)) {
	    im_warn("setting debug level $_=1\n");
	    &set_debug($_, 1);
	}
	&set_verbose(1);
    }
}

#
# flush buffer
#

sub flush (*) {
    local($old) = select(shift);
    $| = 1;
    print '';
    $| = 0;
    select($old);
}

#
# open file
#

sub im_open($$) {
    my ($d, $a) = @_;
    my ($r);
    if ($r = open($d, $a)) {
	binmode($d);
    }
    return $r;
}

sub im_sysopen($$$) {
    my ($d, $f, $a) = @_;
    my ($r);
    if ($r = sysopen($d, $f, $a)) {
	binmode($d);
    }
    return $r;
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
