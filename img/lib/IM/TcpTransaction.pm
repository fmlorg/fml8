# -*-Perl-*-
################################################################
###
###			  TcpTransaction.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::TcpTransaction.pm version 20000414(IM141)";

package IM::TcpTransaction;
require 5.003;
require Exporter;
use IM::Config qw(dns_timeout connect_timeout command_timeout rcv_buf_siz);
use Socket;
BEGIN {
    eval 'use Socket6' unless (eval '&AF_INET6');       # IPv6 patched Perl
}
use IM::Util;
use IM::Ssh;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(log_transaction
	connect_server tcp_command send_command next_response send_data
	command_response set_command_response tcp_logging
	get_session_log set_cur_server get_cur_server get_cur_server_original_form
	pool_priv_sock);

=head1 NAME

TcpTransaction - TCP Transaction processing interface for SMTP and NNTP

=head1 SYNOPSIS

$socket = &connect_server(server_list, protocol, log_flag);
$return_code = &tcp_command(socket, command_string, log_flag);
@response = &command_response;
&set_command_response(response_string_list);

=head1 DESCRIPTION

=cut

use vars qw($Cur_server $Cur_server_original_form $Session_log $TcpSockName
	    $SOCK @Response $Logging @SockPool @Sock6Pool);
BEGIN {
    $Cur_server = '';
    $Session_log = '';
    $TcpSockName = 'tcp00';
}

sub log_transaction () {
    use IM::Log;
}

##### MAKE TCP CONNECTION TO SPECIFIED SERVER #####
#
# connect_server(server_list, protocol, root)
#	server_list: comma separated server list
#	protocol: protocol name to be used with the servers
#	root: privilidge port required
#	return value: handle if success
#
sub connect_server ($$$) {
    my ($servers, $serv, $root) = @_;

    if ($#$servers < 0) {
	im_err("no server specified for $serv\n");
	return '';
    }

    $SIG{'ALRM'} = \&alarm_func;

    no strict 'refs'; # XXX
    local (*SOCK) = \*{$TcpSockName};
    $SOCK = $serv;
    @Response = ();
    my (@he_infos);
    my ($s, $localport, $remoteport);
    foreach $s (@$servers) {
	$Cur_server_original_form = $s;
	my ($r) = ($#$servers >= 0) ? 'skipped' : 'failed';
	# manage server[/remoteport]%localport
	if ($s =~ s/\%(\d+)$//) {
	    $localport = $1;
	    $Cur_server = $s;
	    if ($s =~ s/\/(\d+)$//) {
		$remoteport = $1;
	    } else {
		next unless ($remoteport = getserv($serv, 'tcp'));
	    }
	    if ($main::SSH_server eq 'localhost') {
		im_warn( "Don't use port-forwarding to `localhost'.\n" );
		$Cur_server = "$s/$remoteport";
	    } else {
		if ( $remoteport = &ssh_proxy($s,$remoteport,$localport,$main::SSH_server) ) {
		    $s = 'localhost';
		    $Cur_server = "$Cur_server%$remoteport";
		} else { # Connection failed.
		    im_warn( "Can't login to $main::SSH_server\n" );
		    if ($serv eq 'smtp') {
			&log_action($serv, $Cur_server,
				    join(',', @main::Recipients), $r, @Response);
		    } else { # NNTP
			&log_action($serv, $Cur_server,
				    $main::Newsgroups, $r, @Response);
		    }
		    next;
		}
	    }
	}
	# manage server[/remoteport] notation
	elsif ($s =~ /([^\/]*)\/(\d+)$/) {
	    $remoteport = $2;
	    $s = $1;
	    $Cur_server = "$s/$remoteport";
	} else {
	    $remoteport = $serv;
	    $Cur_server = $s;
	}
	$0 = progname() . ": im_getaddrinfo($s)";
	@he_infos = im_getaddrinfo($s, $remoteport, AF_UNSPEC, SOCK_STREAM);
	if ($#he_infos < 1) {
	    im_warn("address unknown for $s\n");
	    @Response = ("address unknown for $s");
	    if ($serv eq 'smtp') {
		&log_action($serv, $Cur_server,
			    join(',', @main::Recipients), $r, @Response);
	    } else { # NNTP
		&log_action($serv, $Cur_server,
			    $main::Newsgroups, $r, @Response);
	    }
	    next;
	}
	while ($#he_infos >= 0) {
	    my ($family, $socktype, $proto, $sin, $canonname)
		= splice(@he_infos, 0, 5);
	    if ($root && unixp()) {
		my $name = priv_sock($family);
		my $port;
		if ($name eq '') {
		    im_err("privilege port pool is empty.\n");
		    return '';
		}
		if ($family == AF_INET) {
		    $port = (unpack_sockaddr_in($sin))[0];
		} else {
		    $port = (unpack_sockaddr_in6($sin))[0];
		}
		*SOCK = \*{$name};
		$SOCK = $port;
	    } else {
		unless (socket(SOCK, $family, $socktype, $proto)) {
		    im_err("socket creation failed: $!.\n");
		    return '';
		}
		if (defined(rcv_buf_siz())) {
                    unless (setsockopt(SOCK, SOL_SOCKET, SO_RCVBUF, int(rcv_buf_siz()))) {
                        im_err("setsockopt failed: $!.\n");
                        return '';
		    }
                }
	    }

	    im_notice("opening $serv session to $s($remoteport).\n");
	    alarm(connect_timeout()) unless win95p();
	    $0 = progname() . ": connecting to $s with $serv";
	    if (connect (SOCK, $sin)) {
		alarm(0) unless win95p();
		select (SOCK); $| = 1; select (STDOUT);
		$Session_log .= 
		    "Transcription of $serv session follows:\n" if ($Logging);
		im_debug("handle $TcpSockName allocated.\n")
		    if (&debug('tcp'));
		$TcpSockName++;
		return *SOCK;
	    }
	    @Response = ($!);
	    alarm(0) unless win95p();
	    close(SOCK);
	}
	im_notice("$serv server $s($remoteport) did not respond.\n");
	if ($serv eq 'smtp') {
	    &log_action($serv, $Cur_server,
			join(',', @main::Recipients), $r, @Response);
	} else { # NNTP
	    &log_action($serv, $Cur_server,
			$main::Newsgroups, $r, @Response);
	}
    }
    im_warn("WARNING: $serv connection was not established.\n");
    return '';
}

##### CLIENT-SERVER HANDSHAKE #####
#
# tcp_command(channel, command, fake_message)
#	channel: socket descriptor to send the command
#	command: command string to be sent
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub tcp_command ($$$) {
    my ($CHAN, $command, $fake) = @_;
    my ($resp, $stat, $rcode, $logcmd);

    @Response = ();
    $stat = '';
    if ($fake) {
	$logcmd = $fake;
    } else {
	$logcmd = $command;
    }
    if ($command) {
	im_notice("<<< $logcmd\n");
	$Session_log .= "<<< $logcmd\n" if ($Logging);
	unless (print $CHAN "$command\r\n") {
	    # may be channel truoble
	    @Response = ($!);
	    return 1;
	}
	$0 = progname() . ": $logcmd ($Cur_server)";
    } else {
## if you have mysterious TCP/IP bug on IRIX/SGI
#	print $CHAN ' ';
## endif
	$0 = progname() . ": greeting ($Cur_server)";
    }
    do {
	alarm(command_timeout()) unless win95p();
	$! = 0;
	$resp = <$CHAN>;
	unless (win95p()) {
	    alarm(0);
	    if ($!) {	# may be channel truoble
		@Response = ("$!");
		return 1;
	    }
	}
	$resp =~ s/[\r\n]+$//;
	if ($resp =~ /^([0-9][0-9][0-9])/) {
	    $rcode = $1;
	    if ($stat eq '' && $rcode !~ /^0/) {
		$stat = $rcode;
	    }
	    push(@Response, $resp) if ($rcode !~ /^0/);	# XXX
	}
	im_notice(">>> $resp\n");
	$Session_log .= ">>> $resp\n" if ($Logging);
	last if ($resp =~ /^\.$/);
    } while ($resp =~ /^...-/ || $resp =~ /^[^1-9]/);
    return 0 if ($stat =~ /^[23]../);
    return 1 if ($stat =~ /^4../);
    return -1;
}

##### CLIENT-SERVER HANDSHAKE #####
#
# send_command(channel, command, fake_message)
#	return value: the first line of responses
#
sub send_command ($$$) {
    my ($CHAN, $command, $fake) = @_;
    my ($resp, $logcmd);
    if ($command) {
	print $CHAN "$command\r\n";
	if ($fake) {
	    $logcmd = $fake;
	} else {
	    $logcmd = $command;
	}
	im_notice("<<< $logcmd\n");
	$Session_log .= "<<< $logcmd\n" if ($Logging);
	$0 = progname() . ": $logcmd ($Cur_server)";
    } else {
	$0 = progname() . ": greeting ($Cur_server)";
    }
    alarm(command_timeout()) unless win95p();
    $! = 0;
    $resp = <$CHAN>;
    unless (win95p()) {
	alarm(0);
	if ($!) {	# may be channel truoble
	    im_notice("$!\n");
	    return '';
	}
    }
    $resp =~ s/[\r\n]+/\n/;
    im_notice(">>> $resp");
    $Session_log .= ">>> $resp" if ($Logging);
    chomp $resp;
    return $resp;
}

sub send_data ($$$) {
    my ($CHAN, $data, $fake) = @_;
    my ($logdata);
    $data =~ s/\r?\n?$//;
    print $CHAN "$data\r\n";
    if ($fake) {
	$logdata = $fake;
    } else {
	$logdata = $data;
    }
    im_notice("<<< $logdata\n");
    $Session_log .= "<<< $logdata\n" if ($Logging);
}

sub next_response ($) {
    my $CHAN = shift;
    my $resp;

    alarm(command_timeout()) unless win95p();
    $! = 0;
    $resp = <$CHAN>;
    unless (win95p()) {
	alarm(0);
	if ($!) {	# may be channel truoble
	    im_notice("$!\n");
	    return '';
	}
    }
    $resp =~ s/[\r\n]+/\n/;
    im_notice(">>> $resp");
    $Session_log .= ">>> $resp" if ($Logging);
    chomp $resp;
    return $resp;
}

sub command_response () {
    return @Response;
}

sub set_command_response (@) {
    @Response = @_;
}

sub tcp_logging ($) {
#   conversations are saved in $Session_log if true
    $Logging = shift;
}

sub get_session_log () {
    return $Session_log;
}

sub set_cur_server ($) {
    $Cur_server = shift;
}

sub get_cur_server () {
    return $Cur_server;
}

sub get_cur_server_original_form () {
    return $Cur_server_original_form;
}

sub pool_priv_sock ($) {
    my $count = shift;

    pool_priv_sock_af($count, AF_INET);
    if (eval 'pack_sockaddr_in6(110, pack("N4", 0, 0, 0, 0))') {
	no strict 'subs'; # XXX for AF_INET6
	pool_priv_sock_af($count, AF_INET6);
    }
}

sub pool_priv_sock_af ($$) {
    my ($count, $family) = @_;
    my $privport = 1023;

    no strict 'refs'; # XXX
    my ($pe_name, $pe_aliases, $pe_proto);
    ($pe_name, $pe_aliases, $pe_proto) = getprotobyname ('tcp');
    unless ($pe_name) {
	$pe_proto = 6;
    }
    while ($count--) {
	unless (socket(*{$TcpSockName}, $family, SOCK_STREAM, $pe_proto)) {
	    im_err("socket creation failed: $!.\n");
	    return -1;
	}
	while ($privport > 0) {
	    my ($ANYADDR, $psin);

	    im_debug("binding port $privport.\n") if (&debug('tcp'));
	    if ($family == AF_INET) {
		$ANYADDR = pack('C4', 0, 0, 0, 0);
		$psin = pack_sockaddr_in($privport, $ANYADDR);
	    } else {
		$ANYADDR = pack('N4', 0, 0, 0, 0);
		$psin = pack_sockaddr_in6($privport, $ANYADDR);
	    }
	    last if (bind (*{$TcpSockName}, $psin));
	    im_warn("privileged socket binding failed: $!.\n")
		if (&debug('tcp'));
	    $privport--;
	}
	if ($privport == 0) {
	    im_err("binding to privileged port failed: $!.\n");
	    return -1;
	}
	im_notice("pool_priv_sock: $TcpSockName got\n");
	if ($family == AF_INET) {
	    push(@SockPool, $TcpSockName);
	} else {
	    push(@Sock6Pool, $TcpSockName);
	}
	$TcpSockName++;
    }
    return 0;
}

sub priv_sock ($) {
    my ($family) = shift;
    my ($sock_name);

    if ($family == AF_INET) {
	return '' if ($#SockPool < 0);
	$sock_name = shift(@SockPool);
    } else {
	return '' if ($#Sock6Pool < 0);
	$sock_name = shift(@Sock6Pool);
    }
    im_notice("priv_sock: $sock_name\n");
    return $sock_name;
}

sub alarm_func {
    im_die("connection error\n");
}

sub im_getaddrinfo ($$;$$$$) {
    return getaddrinfo(@_) if (defined &getaddrinfo);

    my ($node, $serv, $family, $socktype, $proto, $flags) = @_;

    my ($pe_name, $pe_aliases, $pe_proto, $se_port);
    if (unixp()) {
	$proto = 'tcp' unless ($proto);
	($pe_name, $pe_aliases, $pe_proto) = getprotobyname($proto);
    }
    $pe_proto = 6 unless ($pe_name);
    return unless ($se_port = getserv($serv, $proto));

    my ($he_name, $he_alias, $he_type, $he_len, @he_addrs);
    if ($node =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
	@he_addrs = (pack('C4', $1, $2, $3, $4));
    } else {
	alarm(dns_timeout()) unless win95p();
	($he_name, $he_alias, $he_type, $he_len, @he_addrs)
	  = gethostbyname($node);
	alarm(0) unless win95p();
	return unless ($he_name);
    }

    my ($he_addr, @infos);
    foreach $he_addr (@he_addrs) {
	push(@infos, AF_INET, $socktype, $pe_proto,
	     pack_sockaddr_in($se_port, $he_addr), $he_name);
    }
    @infos;
}

sub getserv($$) {
    my ($serv, $proto) = @_;

    my ($se_port);
    if ($serv =~ /^\d+$/o) {
	$se_port = $serv;
    } else {
	my ($se_name, $se_aliases);
	($se_name, $se_aliases, $se_port) = getservbyname($serv, $proto)
	    if (unixp());
	unless ($se_name) {
	    if ($serv eq 'smtp') {
		$se_port = 25;
	    } elsif ($serv eq 'http') {
		$se_port = 80;
	    } elsif ($serv eq 'nntp') {
		$se_port = 119;
	    } elsif ($serv eq 'pop3') {
		$se_port = 110;
	    } elsif ($serv eq 'imap') {
		$se_port = 143;
	    } else {
		im_err("unknown service: $serv\n");
		return undef;
	    }
	}
    }
    $se_port;
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
