# -*-Perl-*-
################################################################
###
###				Log.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::Log.pm version 20000414(IM141)";

package IM::Log;
require 5.003;
require Exporter;

use IM::Config qw(expand_path used_selectors msg_mode);
use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(log_action);

=head1 NAME

Log - IM log_action

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use vars qw($initialized);
##### WRITE DISPATCHING ACTION HISTORY #####
#
# log_action(protocol, server, to, stat, response)
#	protocol: current protocol to be logged
#	server: server name
#	stat: result status to be logged
#	to: list of recipients
#	return value: none
#
sub log_action ($$$$;@) {
    my ($proto, $server, $to, $stat, @resp) = @_;
#    my ($proto, $server, $id, $to, $stat, @resp) = @_;

    return if ($main::Log_file eq '' && !$main::opt_syslog);

    unless (defined($initialized)) {
	$initialized = 1;
	if ($main::opt_syslog) {
	    require Socket && import Socket;
	    require 'sys/syslog.ph';

	    unless (socket(SYSLOG, &AF_UNIX, &SOCK_DGRAM, 0)) {
		im_warn("syslog socket: $!\n");
		return;
	    }
	    unless (-S &_PATH_LOG) {
		im_warn(&_PATH_LOG . " not found\n");
		return;
	    }
	    my $sun = sockaddr_un(&_PATH_LOG);
	    unless (connect(SYSLOG, $sun)) {
		im_warn("syslog connect: $!\n");
		return;
	    }
	} else {
#	    eval 'use IM::Folder';
	}
    }

    my ($tm_sec, $tm_min, $tm_hour, $tm_mday, $tm_mon, $tm_year)
	= localtime(time);
    my $msg = '';
    $msg = sprintf "%d/%02d/%02d %02d:%02d:%02d ",
      $tm_year + 1900, $tm_mon+1, $tm_mday, $tm_hour, $tm_min, $tm_sec
      unless ($main::opt_syslog);

    $msg .= "proto=$proto";
    $msg .= " server=$server" if ($server);
    $msg .= " id=$main::Cur_mid" if ($main::Cur_mid);
    my $cfg = &used_selectors();
    $msg .= " from=$main::Sender ($cfg)" if ($cfg ne '');
    $msg .= " to=$to" if ($to ne '');
    if ($#resp >= 0) {
	$msg .= " stat=$stat (" . join('/', @resp) . ')';
    } else {
	$msg .= " stat=$stat";
    }

    if ($main::opt_syslog) {
	my $pname = progname() . "[$$]";
	my $sum = &LOG_MAIL + &LOG_INFO;
	send(SYSLOG, "<$sum>$pname: $msg", 0);
	return;
    }

    my $file = expand_path($main::Log_file);
    return unless ($file =~ /^(\S+)$/);
    $file = $1;	# to pass through taint check
    &msg_mode(1);
    unless (im_open(\*HISTORY, ">>$file")) {
	im_warn("can't open history file: $file ($!)\n");
	return;
    }
    unless (print HISTORY "$msg\n") {
	im_warn("can't write to history file: $file ($!)\n");
	close(HISTORY);
	return;
    }
    unless (close(HISTORY)) {
	im_warn("can't write to history file: $file ($!)\n");
    }
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
