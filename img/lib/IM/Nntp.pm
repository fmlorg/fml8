# -*-Perl-*-
################################################################
###
###			       Nntp.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Oct 28, 2003
###

my $PM_VERSION = "IM::Nntp.pm version 20031028(IM146)";

package IM::Nntp;
require 5.003;
require Exporter;

use Fcntl;
use IM::Config qw(nntphistoryfile nntpservers nntpauthuser set_nntpauthuser 
	nntp_timeout);
use IM::TcpTransaction;
use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(
    nntp_open
    nntp_close
    nntp_transaction
    nntp_article
    nntp_list
    nntp_command
    nntp_command_response
    nntp_next_response
    nntp_get_message
    nntp_get_msg
    nntp_head_as_string
    nntp_spec
);

use vars qw($Nntp_opened *NNTPd $NntpErrTitle);

##### NNTP SESSION OPENING #####
#
# nntp_open(server_list)
#	server_list:
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub nntp_open($$) {
    my($servers, $logging) = @_;
    my $rc;

    if ($Nntp_opened) {
	return 0 if (grep(&get_cur_server_original_form() eq $_, @$servers));
	&nntp_close;
    }
    &tcp_logging($logging);
    *NNTPd = &connect_server($servers, 'nntp', 0);
    return 1 if ($NNTPd eq '');
    $NntpErrTitle = "(while talking to " . &get_cur_server() . " with nntp)\n";
    if ($rc = &tcp_command(\*NNTPd, '', '')) {
	return $rc;
    }
    my(@resp) = &command_response;
    if ($resp[0] =~ /InterNetNews server INN/) {
	return 1 if (&tcp_command(\*NNTPd, 'MODE reader', ''));
    }
    $Nntp_opened = 1;
    return 0;
}

##### NNTP SESSION CLOSING #####
#
# nntp_close()
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub nntp_close() {
    return 0 unless ($Nntp_opened);
    $Nntp_opened = 0;
    im_notice("closing NNTP session.\n");
    return 1 if (&tcp_command(\*NNTPd, 'QUIT', ''));
    close(NNTPd);
    return 0;
}

##### NNTP TRANSACTION MANAGEMENT #####
#
# nntp_transaction(server_list, header, body, group, part, total, authuser)
#	server_list: list of NNTP servers
#	group: news group to be posted in
#	part: part number to be sent in partial message mode
#	total: total number of partial messages
#	authuser: User name for NNTP authentication
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub nntp_transaction($$$$$$$) {
    my($servers, $Header, $Body, $group, $part, $total, $authuser) = @_;
    my $rc;

    require IM::Log && import IM::Log;

    &set_nntpauthuser($authuser);
    do {
	$rc = &nntp_transact_sub($servers, $Header, $Body, $part, $total);
	my(@resp) = &command_response;
	if ($rc) {
	    &im_warn($NntpErrTitle . join("\n", @resp) . "\n");
	    $NntpErrTitle = '';
	    &nntp_close;
	    &log_action('nntp', &get_cur_server(), $group,
			($#$servers >= 0) ? 'skipped' : 'failed', @resp);
	    return -1 if ($rc < 0);
            return -1 if (grep(/^(435|437|440|441)/, @resp) > 0);
	} else {
	    &log_action('nntp', &get_cur_server(), $group, 'sent', @resp);
	}
    } while ($rc > 0 && $#$servers >= 0);
    return $rc;
}

##### NNTP TRANSACTION MANAGEMENT SUBROUTINE #####
#
# nntp_transact_sub(server_list, part, total)
#	server_list: list of NNTP servers
#	part: part number to be sent in partial message mode
#	total: total number of partial messages
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub nntp_transact_sub($$$$$) {
    my($servers, $Header, $Body, $part, $total) = @_;
    my $rc;

    return $rc if ($rc = &nntp_open($servers, 1));
    return -1 if (($rc = &nntp_command("POST")) < 0);

    select (NNTPd); $| = 0; select (STDOUT);

    require IM::Message && import IM::Message;

    &set_crlf("\r\n");
    if ($part == 0) {
	return 1 if (&put_header(\*NNTPd, $Header, 'nntp', 'all') < 0);
	return 1 if (&put_body(\*NNTPd, $Body, 1, 0) < 0);
    } else {
	return 1 if (&put_mimed_partial(\*NNTPd, $Header, $Body,
	  'nntp', 1, $part, $total) < 0);
    }
    select (NNTPd); $| = 1; select (STDOUT);
    return $rc if ($rc = &tcp_command(\*NNTPd, '.', ''));
    return 0;
}

sub nntp_head_as_string($) {
    my $i = shift;
    my($rc, $count) = ('', 0);
    local $_;

    im_notice("getting article $i.\n");
    $rc = &tcp_command(\*NNTPd, "HEAD $i", '');
    if ($rc != 0) {
	im_warn("HEAD command failed.\n");
	return -1;
    }
    $count++;
    my($found, $f) = (0, '');
    alarm(nntp_timeout()) unless win95p();
    while (<NNTPd>) {
	alarm(0) unless win95p();
	s/\r\n$/\n/;
	last if ($_ =~ /^\.\n$/);
	s/^\.//;
	im_debug($_) if (&debug('nntp'));
	$f .= $_;
    }
    alarm(0) unless win95p();
    if (!defined($_)) {
	# may be channel trouble
	im_warn("lost connection for HEAD.\n");
	return -1;
    }
    return $f;
}

sub nntp_head($$) {
    my($art_start, $art_end) = @_;
    local $_;
    my $count = 0;

    my $i;
    for ($i = $art_start; $i <= $art_end; $i++) {
	im_notice("getting article $i.\n");
	my $rc = &tcp_command(\*NNTPd, "HEAD $i", '');
	next if ($rc > 0);
	if ($rc < 0) {
	    im_warn("HEAD command failed.\n");
	    return -1;
	}
	$count++;
	my($found, $f) = (0, '');
	alarm(nntp_timeout()) unless win95p();
	while (<NNTPd>) {
	    alarm(0) unless win95p();
	    s/\r\n$/\n/;
	    last if ($_ =~ /^\.\n$/);
	    s/^\.//;
	    im_debug($_) if (&debug('nntp'));
	    if ($f eq '' && /^From:\s*(.*)/i) {
		$found = 1;
		$f = $1;
	    } elsif (/^\s/ && $found) {
		$f .= $_;
	    } else {
		$found = 0;
	    }
	}
	alarm(0) unless win95p();
	if (!defined($_)) {
	    # may be channel trouble
	    im_warn("lost connection for HEAD.\n");
	    return -1;
	}
	$f =~ s/\n[ \t]*/ /g;
	$f = '(sender unknown)' unless ($f);
	print "From $f\n";
    }
    return $count;
}

sub nntp_xover($$) {
    my($art_start, $art_end) = @_;
    my $rc = &tcp_command(\*NNTPd, "XOVER $art_start-$art_end", '');

    if ($rc) {
	im_warn("XOVER command failed.\n");
	return -1;
    }
    my $count = 0;
    my($resp);
    while (($resp = &next_response(\*NNTPd)) !~ /^\.$/) {
	$count++;
	my @overview = split('\t', $resp);

	# 0: article number
	# 1: Subject:
	# 2: From:
	# 3: Date:
	# 4: Message-ID:
	# 5: References:
	# 6: Bytes:
	# 7: Lines:

	print "From $overview[2]\n";
    }
    return $count;
}

sub nntp_article($) {
    my $num = shift;
    local $_;
#   local(@Article);

    im_debug("getting article $num.\n") if (&debug('nntp'));
    my $rc = &tcp_command(\*NNTPd, "ARTICLE $num", '');
    return(1, '') if ($rc > 0);
    if ($rc < 0) {
	im_warn("ARTICLE command failed.\n");
	return(-1, '');
    }
    my @Article = ();
    alarm(nntp_timeout()) unless win95p();
    while (<NNTPd>) {
	alarm(0) unless win95p();
	s/\r\n$/\n/;
	last if ($_ =~ /^\.\n$/);
	s/^\.//;
	push (@Article, $_);
	im_debug($_) if (&debug('nntp'));
    }
    alarm(0) unless win95p();
    if (!defined($_)) {
	# may be channel trouble
	im_warn("lost connection for ARTICLE.\n");
	return(-1, '');
    }
    return(0, \@Article);
}

sub nntp_articles($$$$) {
    my($art_start, $art_end, $dst, $limit) = @_;
    my($rc, $article);
    my $count = 0;
    my $last = 0;

    my $i;
    require IM::MsgStore && import IM::MsgStore;
    for ($i = $art_start; $i <= $art_end; $i++) {
	($rc, $article) = &nntp_article($i);
	next if ($rc > 0);
	if ($rc < 0) {
	    return -1 if ($i == $art_start);
	    im_warn("some articles left due to failure.\n");
	    $last = $i-1;
	    nntp_close();
	    last;
	}
	$count++;

	return -1 if (&store_message($article, $dst) < 0);
	$last = $i;
	last if ($limit && --$limit == 0);
    }
    &exec_getsbrfile($dst);
    return($count, $last);
}

sub nntp_list($) {
    my $group = shift;
    local $_;
    my $rc;

    return -1 if (($rc = &nntp_command("LIST ACTIVE")) < 0);
    if ($rc) {
	im_warn("LIST command failed.\n");
	return -1;
    }
    my $count = 0;
    my $resp;
    while (($resp = &next_response(\*NNTPd)) !~ /^\.$/) {
	next unless (/^$group/);
	$count++;
	print "$resp\n";
    }
    return $count;
}

sub nntp_command($) {
    my $cmd = shift;
    my $rc = &tcp_command(\*NNTPd, $cmd, '');

    return -1 if ($rc < 0);
    if ($rc > 0) {
	my($res) = &command_response();
	if ($res =~ /^480/) {
	    require IM::GetPass && import IM::GetPass;

#	    print "Username: ";
#	    my $user = <STDIN>;
#	    chomp($user);
	    my $user = &nntpauthuser() || 
		$ENV{'USER'} || $ENV{'LOGNAME'} || im_getlogin();
	    my $host = get_cur_server();
	    my($pass, $agtfound, $interact)
		= getpass('nntp', 'PASS', $host, $user);

	    # authenticate for posting
	    return $rc
	      if ($rc = &tcp_command(\*NNTPd, "AUTHINFO USER $user", ''));
	    return $rc
	      if ($rc = &tcp_command(\*NNTPd, "AUTHINFO PASS $pass",
		"AUTHINFO PASS " . "*" x length($pass)));
	    $rc = &tcp_command(\*NNTPd, $cmd, '');
	    return -1 if ($rc < 0);
	}
    }
    return $rc;
}

sub nntp_command_response() {
    return &command_response;
}

sub nntp_next_response() {
    return &next_response(\*NNTPd);
}

sub set_last_article_number($$$) {
    my($server, $group, $number) = @_;
    my($pos, $last, $size) = (0, 0, 0);

    $server =~ s!\%\d+$!!;
    $server =~ s!/\d+$!!;
    my $nntphist = &nntphistoryfile() . '-' . $server;
    if (-f $nntphist) {
	im_open(\*NEWSHIST, "+<$nntphist");
	while ($pos = tell(NEWSHIST), $_ = <NEWSHIST>) {
	    /^([^:]+):\s*(\d+)/;
	    if ($group eq $1) {
		$last = $2;
		im_debug("$last articles in $group ($nntphist)\n")
		  if (&debug('nntp'));
		seek(NEWSHIST, $pos, 0);
		$size = length($_) - length("$group: 0000000\n");
		if ($size < 0) {
		    # no room to rewrite it
		    s/^./#/;
		    print NEWSHIST $_;
		    seek(NEWSHIST, 0, 2);
		    $size = 0;
		}
		printf NEWSHIST "$group: %${size}s%07d\n", '', $number;
		close (NEWSHIST);
		return $last;
	    }
	  }
    } else {
#	open (NEWSHIST, ">$nntphist");
	im_sysopen(\*NEWSHIST, $nntphist, O_RDWR()|O_CREAT());
    }
    seek(NEWSHIST, 0, 2);
    printf NEWSHIST "$group: %${size}s%07d\n", '', $number;
    close (NEWSHIST);
    return $last;
}

sub get_last_article_number($$) {
    my($server, $group) = @_;
    local $_;
    my $number = 0;

    $server =~ s!\%\d+$!!;
    $server =~ s!/\d+$!!;
    my $nntphist = &nntphistoryfile() . '-' . $server;
    if (im_open(\*NEWSHIST, "<$nntphist")) {
	while (<NEWSHIST>) {
	    /^([^:]+):\s*(\d+)/;
	    if ($group eq $1) {
		$number = $2;
		last;
	    }
	}
	close (NEWSHIST);
    }
    return $number;
}


sub nntp_get_message($$) {
    my($src, $msg) = @_;
    my($rc, $art);
    my($group, $srvs) = nntp_spec($src, nntpservers());
    my @servers = split(',', $srvs);
    im_notice("accessing to $group on $srvs.\n");
    do {
	if (($rc = nntp_open(\@servers, 0)) < 0) {
	    return(-1, "can not connect $srvs.\n");
	}
	if (($group ne '') && ($rc = nntp_command("GROUP $group")) < 0) {
	    return(-1, "can not access $group.\n");
	}
    } while (@servers > 0 && $rc > 0);
    return(-1, "can not access $group on $srvs.\n") if ($rc);
    ($rc, $art) = nntp_article($msg);
    nntp_close();
    return(-1, "no message $msg in -$group.\n") if ($rc);
    return(0, $art);
}
 
# returns number of got articles
# -1 if error
sub nntp_get_msg($$$$) {
    my($src, $dst, $how, $limit) = @_;
    my($rc, $group, $error, $art_start, $art_end);
    my($servers, @servers);

    if ($src =~ /^nntp:(.*)/i || $src =~ /^news:(.*)/i) {
	($group, $servers) = &nntp_spec($1, nntpservers());
	@servers = split(',', $servers);
    } else {
	im_warn("no news group specified ($src).\n");
	return -1;
    }

    im_notice("accessing to $group at $servers.\n");

    do {
	if (($rc = &nntp_open(\@servers, 0)) < 0) {
	    im_warn("Connection failed to $servers.\n");
	    return -1;
	}
	return -1 if (($rc = &nntp_command("GROUP $group")) < 0);
    } while (@servers > 0 && $rc > 0);
    return -1 if ($rc);

    my(@resp) = &command_response;
    $error = 0;
    my $i;
    for ($i = 0; $i <= $#resp; $i++) {
	if ($resp[0] =~ /^211 (\d+) (\d+) (\d+) (\S+)/) {
	    if ($4 ne $group) {
		# Should not occur
		$error = 1;
	    } else {
		$art_start = $2;
		$art_end = $3;
	    }
	    last;
	}
    }

    if ($error) {
	&nntp_close;
	return -1;
    }

    my($art_last, $msgs);
    $art_last = &get_last_article_number($servers, $group);
    if ($art_end > $art_last) {
	# new articles
	if ($art_start < $art_last) {
	    $art_start = $art_last + 1;
	}
	$msgs = $art_end - $art_start + 1;
    } else {
	$msgs = 0;
    }

    if ($how eq 'skip') {
#	&nntp_close;
	my $last = &set_last_article_number($servers, $group, $art_end);
	if ($last < $art_end) {
	    my $num = $art_end - $last;
	    im_info("$num article(s) have been marked "
	      ."as read in $group at $servers.\n");
	} else {
	    im_info("no news in $group at $servers.\n");
	}
	return $msgs;
    }

    if ($how eq 'check') {
	if ($msgs > 0) {
	    im_info("$msgs news in $group at $servers.\n");
	} else {
	    im_info("no news in $group at $servers.\n");
	}
#	&nntp_close;
	return $msgs;
    }

    if ($how eq 'from') {
	if ($msgs > 0) {
	    $msgs = &nntp_xover($art_start, $art_end);
	    $msgs = &nntp_head($art_start, $art_end) if ($msgs < 0);
	    if ($msgs < 0) {
		im_warn("can not get article poster information.\n");
		return -1;
	    }
	    im_info("$msgs article(s) in $group at $servers.\n");
	} else {
	    im_info("no news in $group at $servers.\n");
	}
#	&nntp_close;
	return $msgs;
    }

    if ($how eq 'get') {
	my($last);
	if ($msgs > 0) {
	    im_info("Getting new messages from $group at $servers into $dst...\n");
	    ($msgs, $last) = &nntp_articles($art_start, $art_end, $dst, $limit);
	    if ($msgs < 0) {
		im_warn("can not get articles.\n");
		return -1;
	    }
	    im_info("$msgs message(s).\n");
	} else {
	    im_info("no messages in $group at $servers.\n");
	}
#	&nntp_close;
	&set_last_article_number($servers, $group, $last) if ($last);
	return $msgs;
    }

    return -1;
}

# News group (-group[@server])
sub nntp_spec($$) {
    my($spec, $server) = @_;
    my $group;

    if ($spec =~ /^-(.*)/) {
	$group = $1;
    } elsif ($spec =~ /([^@]*)\@(.*)/) {
	$group = $1;
	$server = $2;
    } else {
	$group = $spec;
    }
    return($group, $server);
}

1;

__END__

=head1 NAME

IM::Nntp - NNTP hanlder

=head1 SYNOPSIS

 use IM::Nntp;

 $return_code = &nntp_transaction(server_list, newsgroups,
     part_current, part_total, authuser);
 $return_code = &nntp_close;

Other subroutines:
nntp_open
nntp_article
nntp_list
nntp_command
nntp_command_response
nntp_next_response
nntp_get_message
nntp_get_msg
nntp_head_as_string
nntp_spec

=head1 DESCRIPTION

The I<IM::Nntp> module handles NNTP.

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
