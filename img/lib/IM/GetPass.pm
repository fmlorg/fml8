# -*-Perl-*-
################################################################
###
###			      GetPass.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 30, 1997
### Revised: Oct 28, 2003
###

my $PM_VERSION = "IM::GetPass.pm version 20031028(IM146)";

package IM::GetPass;
require 5.003;
require Exporter;

use IM::Config;
use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(getpass getpass_interact
	     loadpass savepass connect_agent talk_agent findpass);

sub getpass($$$$) {
    my($proto, $auth, $host, $user) = @_;
    my $pass = '';
    my $agtfound = 0;
    my $interact = 0;

    if (&usepwagent()) {
	$pass = &loadpass($proto, $auth, $host, $user);
	$agtfound = 1 if ($pass ne '');
    }
    if ($pass eq '' && &usepwfiles()) {
	$pass = &findpass($proto, $auth, $host, $user);
    }
    my $prompt = lc("$proto/$auth:$user\@$host");
    if ($pass eq '') {
	$pass = &getpass_interact("Password ($prompt): ");
	$interact = 1;
    }
    return ($pass, $agtfound, $interact);
}

sub getpass_interact($) {
    my($prompt) = @_;
    my($secret, $termios, $c_lflag);

    if (! -t STDIN) {
	# stty is not effective for Mule since it's not terminal base.
	# Anyway, Mew never echos back even if getpass echos back.
    } elsif (eval 'require POSIX' & !win95p()) {
	import POSIX qw(termios_h);
	$termios = new POSIX::Termios;
	$termios->getattr(fileno(STDIN));
	$c_lflag = $termios->getlflag;
	$termios->setlflag($c_lflag & ~&POSIX::ECHO);
	$termios->setattr(fileno(STDIN), &POSIX::TCSANOW);
    } elsif (unixp()) {		# non-POSIX-ish UNIX.
	# stty might be available.
	my($OldPath) = $ENV{'PATH'};	# for SUID version
	$ENV{'PATH'} = '/bin:/usr/bin';
	system('/bin/stty -echo'); # Ignore errors.
	$ENV{'PATH'} = $OldPath;
    }
    # POSIX doesn't exist for Win95, sigh.

    print STDERR $prompt;
    flush('STDERR');
    chomp($secret = <STDIN>);
    print STDERR "\n";
    flush('STDERR');

    if (! -t STDIN) {
	# no operation
    } elsif (defined $termios) {	# POSIX-ish
	$termios->setlflag($c_lflag);
	$termios->setattr(fileno(STDIN), &POSIX::TCSANOW);
    } elsif (unixp()) {		# non-POSIX-ish UNIX.
	my($OldPath) = $ENV{'PATH'};	# for SUID version
	$ENV{'PATH'} = '/bin:/usr/bin';
	system('/bin/stty echo');	# Ignore errors.
	$ENV{'PATH'} = $OldPath;
    }

    return $secret;
}

sub loadpass($$$$) {
    my($proto, $auth, $path, $user) = @_;
    local($_);
    my $key = &connect_agent(0);
    return '' if ($key eq '');
    my @keys = unpack('C*', $key);
    my $pass = &talk_agent("LOAD\t$proto\t$auth\t$path\t$user\n");
    if ($pass =~ /^PASS\t(.*)/) {
	my @tmp1 = unpack('C*', pack('H*', $1));
	my $sum1 = $keys[0];
	foreach (@tmp1) {
	    $sum1 += $keys[1];
	    my $tmp2 = $_;
	    $_ -= $sum1;
	    $_ &= 0xff;
	    $sum1 = $tmp2;
	}
	return pack('C*', @tmp1);
    } else {
	return '';
    }
}

sub savepass($$$$$) {
    my($proto, $auth, $path, $user, $pass) = @_;
    local($_);
    my $key = &connect_agent(0);
    return '' if ($key eq '');
    my @keys = unpack('C*', $key);
    my @tmp1 = unpack('C*', $pass);
    my $sum1 = $keys[0];
    foreach (@tmp1) {
	$sum1 += $_ + $keys[1];
	$sum1 &= 0xff;
	$_ = $sum1;
    }
    $pass = unpack('H*', pack('C*', @tmp1));
    &talk_agent("SAVE\t$proto\t$auth\t$path\t$user\nPASS\t$pass\n", 0);
}

sub connect_agent($) {
    my($surpresserror) = shift;
    require Socket && import Socket;

    my $realuser = im_getlogin();
    unless ($realuser) {
	im_warn("pwagent: can not get login name\n") unless ($surpresserror);
	return '';
    }
    my $dir = &pwagent_tmp_path() . "-$realuser";

    my $port = &pwagentport();
    if ($port > 0) {
	unless (socket(SOCK, &AF_INET, &SOCK_STREAM, 0)) {
	    im_warn("pwagent: socket: $!\n") unless ($surpresserror);
	    return '';
	}
	my $sin = sockaddr_in($port, inet_aton('127.0.0.1'));
	unless (connect(SOCK, $sin)) {
	    im_warn("pwagent: connect: $!\n") unless ($surpresserror);
	    return '';
	}
    } else {
	my $name = "$dir/pw";

	unless (-S $name) {
	    im_warn("pwagent: can not access to socket: $name\n")
		unless ($surpresserror);
	    return '';
	}

	my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev) = stat($dir);
	if ($mode & 0077) {
	    im_warn("pwagent: invalid mode: $dir\n") unless ($surpresserror);
	    return '';
	}
	($dev,$ino,$mode,$nlink,$uid,$gid,$rdev) = stat($name);
	if ($mode & 0077) {
	    im_warn("pwagent: invalid mode: $name\n") unless ($surpresserror);
	    return '';
	}

	unless (socket(SOCK, &AF_UNIX, &SOCK_STREAM, 0)) {
	    im_warn("pwagent: socket: $!\n") unless ($surpresserror);
	    return '';
	}
	my $sun = sockaddr_un($name);
	unless (connect(SOCK, $sun)) {
	    im_warn("pwagent: connect: $!\n") unless ($surpresserror);
	    return '';
	}
    }
    select(SOCK); $| = 1; select(STDOUT);
    my $res = <SOCK>;
    chomp($res);
    return $res;
}

sub talk_agent($) {
    my($msg) = shift;
    print SOCK $msg;
    my $res = <SOCK>;
    shutdown (SOCK, 2);
    close(SOCK);
    chomp($res);
    return $res;
}

sub findpass($$$$) {
    my($proto, $auth, $host, $user) = @_;
    local($_);
    my($passfile);

    foreach $passfile (split(',', &pwfiles())) {
	$passfile = &expand_path($passfile);
	next unless (open (PASSFILE, "<$passfile"));
	while (<PASSFILE>) {
	    chomp;
	    next if (/^(#.*)?$/); 
#	    s/\s+(\#.*)?$//;	# remove comments
	    if (/^(\S+)\s+(\S+)\s+(\S+)\s+(\S.+)$/) {
		my($tmp_host, $tmp_user, $tmp_pass) = ($2, $3, $4);
		my($tmp_proto, $tmp_auth) = split('/', $1);
		if (($tmp_proto eq $proto)
		    && ($tmp_auth eq $auth)
		    && ($tmp_host eq $host)
		    && ($tmp_user eq $user)) {
		    close (PASSFILE);
		    return $tmp_pass;
		}
	    }
	}
	close (PASSFILE);
    }

    return '';
}

1;

__END__

=head1 NAME

IM::GetPass - get password from tty or ...

=head1 SYNOPSIS
    
 use IM::GetPass;

 ($pass, $agtfound, $interact) = getpass('imap', $auth, $host, $user);

=head1 DESCRIPTION

The I<IM::GetPass> module handles password for mail/news servers.

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
