# -*-Perl-*-
################################################################
###
###				Pop.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Feb 28, 2000
###

my $PM_VERSION = "IM::Pop.pm version 20000228(IM140)";

package IM::Pop;
require 5.003;
require Exporter;

use IM::Config;
use IM::Util;
use IM::TcpTransaction;
use IM::GetPass;
use IM::MD5;
use IM::MsgStore;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(pop_get_msg pop_spec);

=head1 NAME

Pop - POP handling package

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use vars qw(*POPd $SERVER_IDENT %history %newhistory);
#######################
# POP access routines #
#######################

# pop_open(proto, host, user, pass)
#	proto:	"POP"
#		"APOP"
#		"RPOP"
#	host:
#	user:
#	pass:
#	return value:
#		 0: success
#		-1: failure
#		-2: failure (connection)
#
sub pop_open ($$$$) {
    my ($auth, $host, $user, $pass) = @_;
    my $prompt = lc("pop/$auth:$user\@$host");
    my ($resp, $pwd, $errmsg);
    my (@host_list) = ($host);
    im_notice("opening POP session ($auth)\n");
    if ($auth eq 'RPOP' && !$main::SUIDROOT) {
	im_warn("RPOP operation requires SUID root.\n");
	return -1;
    }
    &tcp_logging(0);
    *POPd = &connect_server(\@host_list, 'pop3', ($auth eq 'RPOP')?1:0);
    unless ($POPd) {
	im_warn("connection failed.\n");
	return -2;
    }
    $resp = &send_command(\*POPd, '', '');
    if ($resp !~ /^\+/) {
	im_warn("POP protocol error.\n");
	return -1;
    }
    if ($resp =~ /at ([\w\-.]+) /) {
	$SERVER_IDENT = "$user\@$1";
    } else {
	$SERVER_IDENT = "$user\@unknown";
    }
    if ($auth eq 'POP') {
	$resp = &send_command(\*POPd, "USER $user", '');
	if ($resp !~ /^\+/) {
	    im_err("login failed ($resp).\n");
	    return -1;
	}
	$resp =  &send_command(\*POPd, "PASS $pass", 'PASS ********');
	if ($resp !~ /^\+/) {
	    if ($resp =~ /IN-USE/) {
		im_err("session is in use ($prompt) [$resp].\n");
	    } else {
		im_err("invalid password ($prompt) [$resp].\n");
	    }
	    return -1;
	}
    } elsif ($auth eq 'RPOP') {
	$resp = &send_command(\*POPd, "USER $user", '');
	if ($resp !~ /^\+/) {
	    im_err("login failed ($resp).\n");
	    return -1;
	}
	my $realuser = im_getlogin();
	$resp =  &send_command(\*POPd, "RPOP $realuser", "");
	if ($resp !~ /^\+/) {
	    im_err("invalid password ($prompt) [$resp].\n");
	    return -1;
	}
    } elsif ($auth eq 'APOP') {
	if ($resp !~ /^\+.*(<.+>)/i) {
	    im_err("APOP is not supported by the server.\n");
	    return -1;
	}
	$pwd = &md5_str($1.$pass);
	$resp =  &send_command(\*POPd, "APOP $user $pwd",
	  "APOP $user MD5-digest-of-password");
	if ($resp !~ /^\+/) {
	    im_err("invalid password ($prompt) [$resp].\n");
	    return -1;
	}
    } else {
	im_err("Unknown Protocol: $auth.\n");
	return -1;
    }
    return 0;
}

sub pop_close () {
    im_notice("closing POP session.\n");
    my $resp = &send_command(\*POPd, 'QUIT', '');
    return -1 if ($resp !~ /^\+/);
    close(POPd);
    return 0;
}

sub pop_stat () {
    my (@field);
    im_notice("getting number of message.\n");
    my $resp = &send_command(\*POPd, 'STAT', '');
    if ($resp !~ /^\+/) {
	im_warn("STAT command failed.\n");
	return -1;
    }
    @field = split(' ', $resp);
    im_notice("$field[1] message(s) found.\n");
    return $field[1];
}

sub pop_retr ($$$) {
    my ($num, $dst, $noscan) = @_;
    local ($_);
    my (@Message);
    im_notice("getting message $num.\n");
    my $resp = &send_command(\*POPd, "RETR $num", '');
    if ($resp !~ /^\+/) {
	im_warn("RETR command failed.\n");
	return -1;
    }
    alarm(pop_timeout()) unless win95p();
    $! = 0;
    while (<POPd>) {
	unless (win95p()) {
	    alarm(0);
	    if ($!) {	# may be channel truoble
		im_warn("lost connection for RETR.\n");
		return -1;
	    }
	}
	s/\r\n$/\n/;
	last if ($_ =~ /^\.\n$/);
	s/^\.//;
	im_debug($_) if (&debug('pop'));
	push (@Message, $_);
    }
    alarm(0) unless win95p();

    return -1 if (store_message(\@Message, $dst, $noscan) < 0);
    &exec_getsbrfile($dst);

    return 0;
}

sub pop_head ($) {
    my $num = shift;
    im_notice("getting header of message $num.\n");
    my $resp = &send_command(\*POPd, "TOP $num 1", '');
    if ($resp !~ /^\+/) {
	im_warn("TOP command failed.\n");
	return 0;
    }
    my ($field, $inheader) = ('', 1);
    local ($_);
    my (%head);
    undef %head;
    alarm(pop_timeout()) unless win95p();
    $! = 0;
    while (<POPd>) {
	unless (win95p()) {
	    alarm(0);
	    if ($!) {	# may be channel truoble
		im_warn("lost connection for HEAD.\n");
		return 0;
	    }
	}
	s/\r?\n$//;
	last if ($_ =~ /^\.$/);
	s/^\.//;
	if ($inheader) {
	    im_debug($_) if (&debug('pop'));
	    if (/^\s/) {
		s/^\s+//;
		$head{$field} = $head{$field} . $_;
		next;
	    } elsif (/^([^:]+):\s*(.*)/) {
		$field = lc($1);
		$head{$field} = $2;
	    } else {
		$inheader = 0;
		next;
	    }
	} else {
	    $head{'BODY'} .= $_;
	}
    }
    alarm(0) unless win95p();
    return \%head;
}

sub pop_dele ($) {
    my $num = shift;
    im_notice("deleting message $num.\n");
    my $resp = &send_command(\*POPd, "DELE $num", '');
    if ($resp !~ /^\+/) {
	im_warn("DELE command failed.\n");
	return -1;
    }
    return 0;
}

sub pop_uidl ($) {
    my $uidlp = shift;
    local $_;
    im_notice("getting UIDL information.\n");
    my $resp = &send_command(\*POPd, 'UIDL', '');
    if ($resp !~ /^\+/) {
	im_warn("UIDL command failed.\n");
	return -1;
    }
    alarm(pop_timeout()) unless win95p();
    $! = 0;
    while (<POPd>) {
	unless (win95p()) {
	    alarm(0);
	    if ($!) {	# may be channel truoble
		im_warn("lost connection for UIDL.\n");
		return -1;
	    }
	}
	s/\r\n$/\n/;
	last if ($_ =~ /^\.\n$/);
	im_debug($_) if (&debug('pop'));
	if (/^(\d+)\s(\S+)$/) {
	    $$uidlp[$1] = $2;
	}
    }
    alarm(0) unless win95p();
    return 0;
}

# pop_process(socket, how)
sub pop_process ($$$$) {
    my ($how, $host, $dst, $noscan) = @_;
    my ($histfile, $head, $msgs, $i, $h, $new, $last);
    return -1 if (($msgs = &pop_stat) < 0);

    my $keep_proto = 'UIDL';	# UIDL/LAST/STATUS/MSGID
    if ($main::opt_protokeep =~ /uidl/i) {
	$keep_proto = 'UIDL';
    } elsif ($main::opt_protokeep =~ /last/i) {
	$keep_proto = 'LAST';
    } elsif ($main::opt_protokeep =~ /status/i) {
	$keep_proto = 'STATUS';
    } elsif ($main::opt_protokeep =~ /msgid/i) {
	$keep_proto = 'MSGID';
    }

    my @uidl = ();
    local %history;
    local %newhistory;	# just for STATUS/MSGID
    local $_;

    # get information on the previous access
    $last = 0;
    if ($msgs > 0 && $main::opt_keep != 0) {
	$histfile = &pophistoryfile();
	$histfile =~ s/{POPSERVERID}/$SERVER_IDENT/e;
	if ($histfile eq '') {
	    im_err("POP historyfile $histfile undefined.\n");
	    return -1;
	} elsif ($histfile =~ /(\S+)/) {
	    $histfile = $1;	# to pass through taint check
	} else {
	    im_err("invalid POP historyfile: $histfile.\n");
	    return -1;
	}
	im_notice("reading POP history: $histfile\n");
	if (im_open(\*HIST, "<$histfile")) {
	    while (<HIST>) {
		chomp;
		if (/^(\S+)\s(\d+)$/) {
		    $history{$1} = $2;
		}
	    }
	    close (HIST);
	}
	if ($keep_proto eq 'UIDL') {
	    &pop_uidl(\@uidl);
	} elsif ($keep_proto eq 'LAST') {
	    my $resp = &send_command(\*POPd, 'LAST', '');
	    if ($resp !~ /^\+/) {
		im_warn("LAST command failed.\n");
	    } else {
		$resp =~ /\+OK (\d+)/i;
		$last = $1;
	    }
#	} elsif ($keep_proto eq 'STATUS') {
#	    # nothing
#	} elsif ($keep_proto eq 'MSGID') {
#	    # nothing
	}

    }
    $last++;

    # now, let's start to access messages
    $new = 0;
    if ($how eq 'check') {
	if ($msgs > 0) {
	    if ($main::opt_keep != 0) {
		if ($keep_proto eq 'UIDL') {
		    for ($i = $last; $i <= $msgs; $i++) {
			next if ($uidl[$i] eq '');
			next if ($history{$uidl[$i]} ne '');
			$new++;
		    }
		} elsif ($keep_proto eq 'LAST') {
		    $msgs -= $last - 1;
		} elsif ($keep_proto eq 'STATUS') {
		    for ($i = $last; $i <= $msgs; $i++) {
			$head = pop_head($i);
			next if ($head->{'status'} =~ /RO/);
			$new++;
		    }
		} elsif ($keep_proto eq 'MSGID') {
		    for ($i = $last; $i <= $msgs; $i++) {
			$head = pop_head($i);
			my $mid = $head->{'message-id'};
			$mid =~ s/.*<(.*)>.*/$1/;
			next if ($history{$mid} ne '');
			$new++;
		    }
		}
		if ($new > 0) {
		    im_info("$new new message(s) at $host.\n");
		} else {
		    im_info("no new message at $host.\n");
		}
	    } else {
		im_info("$msgs message(s) at $host.\n");
		$new = $msgs;
	    }
	} else {
	    im_info("no message at $host.\n");
	}
    } elsif ($how eq 'from') {
	if ($msgs > 0) {
	    for ($i = $last; $i <= $msgs; $i++) {
		if ($main::opt_keep != 0 && $keep_proto eq 'UIDL') {
		    next if ($uidl[$i] eq '');
		    next if ($history{$uidl[$i]} ne '');
		}
		$head = &pop_head($i);
		return -1 unless ($head);
		if ($main::opt_keep != 0) {
		    if ($keep_proto eq 'STATUS') {
			next if ($head->{'status'} =~ /RO/);
		    } elsif ($keep_proto eq 'MSGID') {
			my $mid = $head->{'message-id'};
			$mid =~ s/.*<(.*)>.*/$1/;
			next if ($history{$mid} ne '');
		    }
		}
		my $f = $head->{'from'};
		$f =~ s/\s+/ /g;
		$f = "(sender unknown)" unless ($f);
		print "From $f\n";
		$new++;
	    }
	    if ($new > 0) {
		im_info("$new message(s) at $host.\n");
	    } else {
		im_info("no new message at $host.\n");
	    }
	} else {
	    im_info("no message at $host.\n");
	}
    } elsif ($how eq 'get') {
	$new = pop_inc($msgs, $host, $dst, $last,
		       $keep_proto, \%history, \@uidl, $noscan);

	if ($new > 0 && $main::opt_keep != 0) {
	    im_notice("writing UIDL history: $histfile\n");
	    if (im_open(\*HIST, ">$histfile")) {
		if ($keep_proto eq 'UIDL') {
		    for ($i = 1; $i <= $msgs; $i++) {
			if (($h = $uidl[$i]) ne '' && $history{$h} > 0) {
			    print HIST "$h $history{$h}\n";
			}
		    }
		} elsif ($keep_proto eq 'LAST') {
		    # XXX
		} elsif ($keep_proto eq 'STATUS' || $keep_proto eq 'MSGID') {
		    foreach (keys %newhistory) {
			print HIST "$_ $newhistory{$_}\n";
		    }
		}
		close (HIST);
	    }
	}
    }
    return $new;
}

sub pop_inc ($$$$$$$$) {
    my ($msgs, $host, $dst, $last, $keep_proto, $histp, $uidlp, $noscan) = @_;
    my ($accesstime, $i, $h, $head);
    my $got = 0;
    my $ttl = 0;

    if ($msgs <= 0) {
	im_info("no message at $host.\n");
	return 0;
    }

    if ($main::opt_keep >= 0) {
	$ttl = $main::opt_keep * 60*60*24;
    } else {
	$ttl = -1;
    }
    $accesstime = time;

    my $getchk_hook = getchksbr_file();
    if ($getchk_hook) {
	if ($getchk_hook =~ /^(\S+)$/) {
	    if ($main::INSECURE) {
		im_warn("Sorry, GetChkSbr is ignored for SUID root script.\n");
	    } else {
		$getchk_hook = $1;    # to pass through taint check
		if (-f $getchk_hook) {
		    require $getchk_hook;
		} else {
		    im_err("scan subroutine file $getchk_hook not found.\n");
		}
	    }
	}
    }

    im_info("Getting new messages into $dst....\n");
    for ($i = $last; $i <= $msgs; $i++) {
	if ($getchk_hook ne '') {
	    $head = &pop_head($i);
            next unless (eval { &getchk_sub($head); });
	}
	if ($main::opt_keep != 0) {
	    if ($keep_proto eq 'UIDL') {
		if ($$uidlp[$i] eq '') {
		    im_notice("no UIDL info. from the server.\n");
		    next;
		}
		if ($$histp{$$uidlp[$i]} ne '') {
		    im_notice("found UIDL info. in the history.\n");
		    if ($ttl >= 0
		      && $$histp{$$uidlp[$i]} + $ttl < $accesstime) {
			im_notice("too old message; deleted.\n");
			if (&pop_dele($i) >= 0) {
			    $$histp{$$uidlp[$i]} = 0;
			}
		    }
		    next;
		}
		$$histp{$$uidlp[$i]} = $accesstime;
	    } elsif ($keep_proto eq 'STATUS' || $keep_proto eq 'MSGID') {
		$head = &pop_head($i) if ($getchk_hook eq '');
		my $mid = $head->{'message-id'};
		next if ($mid eq '');
		$mid =~ s/.*<(.*)>.*/$1/;
		if ($head->{'status'} =~ /RO/) {
		    if ($$histp{$mid} ne '') {
			im_notice("found Message-Id info. in the history.\n");
			if ($ttl >= 0 && $$histp{$mid} + $ttl < $accesstime) {
			    im_notice("too old message; deleted.\n");
			    next if (&pop_dele($i) >= 0);
			}
			$newhistory{$mid} = $$histp{$mid};
			next;
		    } elsif ($keep_proto eq 'STATUS') {
			$newhistory{$mid} = $accesstime;
			next;
		    }
		}
		$newhistory{$mid} = $accesstime;
#	    } elsif ($keep_proto eq 'LAST') {
#		# XXX everything will be kept
	    }
	}
	return -1 if (pop_retr($i, $dst, $noscan) < 0);
	$got++;
	if ($main::opt_keep == 0) {
	    # delete current message
	    return -1 if (&pop_dele($i) < 0);
	}
    }
    flush('STDOUT');
    if ($got > 0) {
	im_info("$got message(s).\n");
    } else {
	im_info("no new message at $host.\n");
    }
    return $got;
}

sub pop_get_msg ($$$$) {
    my ($src, $dst, $how, $noscan) = @_;

    $src =~ s/^pop//i;

    my ($auth, $user, $host) = &pop_spec($src);

    my ($pass, $agtfound, $interact) = ('', 0, 0);
    ($pass, $agtfound, $interact) = 
	getpass ('pop', $auth, $host, $user) unless $auth eq 'RPOP';

    my $msgs = 0;
    im_notice("accessing POP/$auth:$user\@$host for $how\n");
    my $rc = &pop_open($auth, $host, $user, $pass);
    unless ($rc) {
	&savepass('pop', $auth, $host, $user, $pass)
	    if ($auth ne 'RPOP' && $interact && $pass ne '' && &usepwagent());
	$msgs = pop_process($how, $host, $dst, $noscan);
	if ($msgs < 0) {
	    im_warn("POP processing error.\n");
	}
	&pop_close();
    } elsif ($rc == -1) {
	im_err("POP connection was not established.\n");
	&savepass('pop', $auth, $host, $user, '')
	    if ($auth ne 'RPOP' && $agtfound && &usepwagent());
    } else {
	im_err("POP connection was not established.\n");
    }
    return $msgs;
}

# POP folder (--src=pop[//auth][:user][@server[/port]])
sub pop_spec ($) {
    my $spec = shift;

    if ($spec eq '' || $spec !~ /[:\@]|\/\//) {
	my $s = popaccount();
	if ($s !~ /^[\/\@:]/) {
	    if ($s =~ /\@/) {
		$s = ":$s";
	    } else {
		$s = "\@$s";
	    }
	}
	$spec .= $s if ($s ne '');
    }
    my ($auth, $host) = ('apop', 'localhost');
    my $user = $ENV{'USER'} || $ENV{'LOGNAME'} || im_getlogin();

    if ($spec =~ /^\/\/?(\w+)(.*)/) {
	$auth = $1;
	$spec = $2;
    }
    if ($spec =~ /(.*)\@(.*)/) {
	$host = $2;
	$spec = $1;
    }
    if ($spec =~ /^:(.*)/) {
	$user = $1;
	$spec = '';
    }
    if ($spec ne '') {
	im_warn("invalid pop spec: $spec\n");
	return ('', '', '');
    }

    if ($auth =~ /^pop$/i) {
	$auth = 'POP';
    } elsif ($auth =~ /^apop$/i) {
	$auth = 'APOP';
    } elsif ($auth =~ /^rpop$/i) {
	$auth = 'RPOP';
    } else {
	im_warn("unknown authentication protocol: $auth\n");
	return ('', '', '');
    }

    return ($auth, $user, $host);
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
