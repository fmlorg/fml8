# -*-Perl-*-
################################################################
###
###			  Ssh.pm
###
### Author:  Masatoshi Tsuchiya <tsuchiya@pine.kuee.kyoto-u.ac.jp>
###	Internet Message Group <img@mew.org>
### Created: Oct 05, 1999
### Revised: Oct 28, 2003
###

my $PM_VERSION = "IM::Ssh.pm version 20031028(IM146)";

package IM::Ssh;
require 5.003;
require Exporter;
use IM::Config qw(connect_timeout command_timeout ssh_path);
use IM::Util;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $SSH $FH @PID);
@ISA       = qw(Exporter);
@EXPORT    = qw(ssh_proxy);

# Global Variables
$FH      = "SSH00000";
@PID     = ();

sub ssh_proxy($$$$) {
    my($server, $remote, $local, $host) = @_;
    my $prog = ssh_path();

    unless ($host) {
	im_err("Missing relay host.\n");
	return 0;
    }
    im_notice("openning SSH-tunnel to $server/$remote\%$local via $host\n")
	if &verbose;

    my($pid, $read, $write);
  FORK: {
	no strict 'refs';
	$read  = $FH++;
	$write = $FH++;
	pipe($read, $write);
	if ($pid = fork) {
	    close $write;
	    my($buf, $sig, $i);
	    for ($i=0; $i<3; $i++) {
		$sig = $SIG{ALRM};
		$SIG{ALRM} = sub { die "SIGALRM is received\n"; };
		eval {
		    alarm &connect_timeout();
		    $buf = <$read>;
		    alarm 0;
		};
		$SIG{ALRM} = $sig;
		if ($@ !~ /SIGALRM is received/) {
		    push(@PID, $pid);
		    if ($buf =~ /ssh_proxy_connect/) {
			return $local;
		    } elsif ($buf =~ /Local: bind: Address already in use/) {
			$local++;
			redo FORK;
		    } elsif ($buf) {
			last;
		    }
		}
	    }
	    $buf =~ s/\s+$//;
	    $buf =~ s/\n/\\n/g;
	    im_warn("Accident in Port Forwading: $buf\n");
	} elsif ($pid == 0) {
	    close $read;
	    open(STDOUT, ">&$write");
	    open(STDERR, ">&$write");
 	    exec($prog, '-n', '-x', '-o', 'BatchMode yes',
		 "-L$local:$server:$remote", $host,
		 sprintf('echo ssh_proxy_connect ; sleep %s',
			 &command_timeout()));
	    exit 0;			# Not reach.
	} elsif ($! =~ /No more process/) {
	    sleep 5;
	    redo FORK;
	} else {
	    im_warn("Can't fork $prog.\n");
	}
    }
    0;
}


sub END {
    if (@PID) {
	kill 15, @PID;
	sleep 3;
	kill 9, @PID;
    }
}

1;

__END__

=head1 NAME

IM::Ssh - SSH handler

=head1 SYNOPSIS

 use IM::Ssh;

 if ($remote = ssh_proxy($server, $remote, $local, $host)) {
     # connection succeeded
 } else {
     # connection failed
 }

=head1 DESCRIPTION

The I<IM::Ssh> module handles SSH.

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
