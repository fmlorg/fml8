# -*-Perl-*-
################################################################
###
###				Http.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Jun  1, 2003
###

my $PM_VERSION = "IM::Http.pm version 20030601(IM145)";

package IM::Http;
require 5.003;
require Exporter;

use IM::Util;
use IM::TcpTransaction;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(http_process http_spec);

use vars qw(*HTTPd);

########################
# HTTP access routines #
########################

# http_open(host, port, user, pass)
#	host:
#	port:
#	user:
#	pass:
#	return value:
#		 0: success
#		-1: failure
#
sub http_open($$) {
    my($host, $port) = @_;
    my($resp);
    my(@host_list);
    if ($port ne '' && $port != 0 && $port != 80) {
	@host_list = ("$host/$port");
    } else {
	@host_list = ($host);
    }
    im_notice("opening HTTP session\n");
    &tcp_logging(0);
    *HTTPd = &connect_server(\@host_list, 'http', 0);
    unless ($HTTPd) {
	im_warn("connection failed.\n");
	return -1;
    }
    return 0;
}

sub http_close() {
    im_notice("closing HTTP session.\n");
    close(HTTPd);
    return 0;
}

sub http_get($$$) {
    my($path, $user, $pass) = @_;
    local($_);
    my(@Message);
    im_notice("getting $path.\n");
    &send_data(\*HTTPd, "GET $path HTTP/1.0", '');
    if ($pass ne '') {
	require IM::EncDec && import IM::EncDec;
	my $cred = &b_encode_string("$user:$pass");
	&send_data(\*HTTPd, "Authorization: Basic $cred",
	    'Authorization: ********');
    }
    &send_data(\*HTTPd, '', '');
    @Message = ();
    while (<HTTPd>) {
	push (@Message, $_);
    }
    return \@Message;
}

# http_process(spec)
sub http_process($;$$) {
    my($spec, $http_proxy, $no_proxy) = @_;
    my($msg, $rcode, $auth);
    my($user, $host, $port, $path);
    my($target_host, $target_port);

    $http_proxy = '' if ($no_proxy && $spec =~ /$no_proxy/);

    if ($http_proxy) {
	im_notice("using proxy: $http_proxy\n");
	if ($http_proxy =~ /(.*):(.*)/) {
	    $target_host = $1;
	    $target_port = $2;
	} else {
	    $target_host = $http_proxy;
	    $target_port = '';
	}
    }

    my $pass = '';
    my $retry = 3;
    my $first = 1;
    my $found = 0;
    while (1) {
	($user, $host, $port, $path) = &http_spec($spec);

	if ($http_proxy ne '') {
	    if ($port ne '' && $port != 0 && $port != 80) {
		$path = "http://$host:$port$path";
	    } else {
		$path = "http://$host$path";
	    }
	} else {
	    $target_host = $host;
	    $target_port = $port;
	}

	return (-1) if (http_open($target_host, $target_port) < 0);
	$msg = http_get($path, $user, $pass);
	http_close();

	im_debug("HTTP response for $spec follows\n") if (&debug('http'));
	my $new_spec = 0;
	$rcode = 0;
	$auth = '';
	$pass = '';
	while ($_ = shift(@$msg)) {
	    s/\r?\n//;
	    if (/^HTTP\/\S+\s+(\d+)/i) {
		$rcode = $1;
	    }
	    if (/^Location:\s*(.*)/i) {
		$spec = $1;
		$new_spec = 1;
	    }
	    if (/^WWW-Authenticate:\s*(.*)/i) {
		$auth = $1;
	    }
	    im_debug("$_\n") if (&debug('http'));
	    last if (/^$/);
	}

	next if ($rcode == 302 && $new_spec);
	if ($rcode == 401 && $auth =~ /Basic/i && $retry--) {
	    require IM::GetPass && import IM::GetPass;
	    if ($first) {
		$first = 0;
		if (&usepwagent()) {
		    $pass = &loadpass('http', $auth, $path, $user);
		    if ($pass ne '') {
			$found = 1;
			next;
		    }
		}
		if (&usepwfiles()) {
		    $pass = &findpass('http', $auth, $path, $user);
		    if ($pass ne '') {
			$found = 1;
			next;
		    }
		}
	    }
#	    last if ($found && $NoPwQueryOnFail);
	    $pass = &getpass_interact("Password: "); #xxx
	    next if ($pass ne '');
	}
	if ($rcode == 200 && $pass ne '' && &usepwagent()) {
	    &savepass('http', $auth, $path, $user, $pass);
	}
	last;
    }

    return (0, $msg);
}

# HTTP (--src=http://[user@]server[:port]/path)
sub http_spec($) {
    my $spec = shift;

    if ($spec eq '') {
	$spec = httphome();
    }
    $spec =~ s/^http://i;
    my $host = 'localhost';
    my $user = $ENV{'USER'} || $ENV{'LOGNAME'} || im_getlogin();
    my $port = 0;
    my $path;

    if ($spec =~ m|^//([^/]+)(/.*)?|) {
	my $s = $1;
	$path = $2;
	if ($s =~ /(.*)\@(.*)/) {
	    $user = $1;
	    $s = $2;
	}
	if ($s =~ /(.*):(.*)/) {
	    $host = $1;
	    $port = $2;
	} else {
	    $host = $s;
	}
    } else {
	$path = $spec;
    }

    return ($user, $host, $port, $path);
}

1;

__END__

=head1 NAME

IM::Http - HTTP handler

=head1 SYNOPSIS

 use IM::Http;

 (rc, data) = http_process(spec, http_proxy, no_proxy)
     rc: 
         0: success
         -1: failure

=head1 DESCRIPTION

The I<IM::Http> module handles HTTP.

This modules is provided by IM (Internet Message).

=head1 EXAMPLES

 my($rc, $data) = http_process($spec, httpproxy(), noproxy())
 if ($rc < 0) {
     exit 1;
 }
 foreach (@$data) {
     print;
 }

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
