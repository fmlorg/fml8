# -*-Perl-*-
################################################################
###
###			       Smtp.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Jun  1, 2003
###

my $PM_VERSION = "IM::Smtp.pm version 20030601(IM145)";

package IM::Smtp;
require 5.003;
require Exporter;

use IM::Config;
use IM::Util;
use IM::Log;
use IM::Message qw(message_size put_header put_body put_mimed_bcc
		   put_mimed_partial put_mimed_error_notify set_crlf);
use IM::TcpTransaction;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(smtp_open smtp_close smtp_transaction
	smtp_transaction_for_error_notify);

use vars qw(@Status $Smtp_opened *SMTPd $SmtpErrTitle
	    $Esmtp_flag %ESMTP);
##### SMTP SESSION OPENING #####
#
# smtp_open(server, server_list, log_flag)
#	server: current server
#	server_list:
#	log_flag: conversations are saved in $Session_log if true
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub smtp_open($$$) {
    my($server, $server_list, $logging) = @_;
    local $_;
    my $rc;
    my $svr = &get_cur_server_original_form();
    @Status =();
    if ($Smtp_opened) {
	if (grep {$svr eq $_} @$server_list) {
	    im_notice("resetting SMTP session.\n");
	    return 0 unless (&tcp_command(\*SMTPd, 'RSET', ''));
	}
	&smtp_close;
#	return 1;
    }
    &tcp_logging($logging);
    my @s = ($server);
    *SMTPd = &connect_server(\@s, 'smtp', 0);
    return 1 if ($SMTPd eq '');
    $SmtpErrTitle = "(while talking to " . &get_cur_server() . " with smtp)\n";
    return $rc if ($rc = &tcp_command(\*SMTPd, '', ''));
    $Esmtp_flag = 0;
    my(@resp) = &command_response;
    if (join('/', @resp) =~ /ESMTP/) {
	$Esmtp_flag = 1;
    }
    $main::Client_name = 'localhost' unless ($main::Client_name);
    if ($Esmtp_flag) {
	unless (&tcp_command(\*SMTPd, "EHLO $main::Client_name", '')) {
	# ESMTP OK
	my(@resp) = &command_response;
	foreach (@resp) {
	    if (/^250[ \-]([A-Z0-9]+)$/) {
		$ESMTP{$1} = 1;
	    }
	}
	$Smtp_opened = 1;
	&tcp_command(\*SMTPd, 'VERB', '')
	  if ($ESMTP{'VERB'} && &debug('smtp'));
	    return 0;
	}
	$Esmtp_flag = 0;
    }
    # fall back to traditional SMTP
    $rc = &tcp_command(\*SMTPd, "HELO $main::Client_name", '');
    return $rc if ($rc);
    $Smtp_opened = 1;
    &tcp_command(\*SMTPd, 'VERB', '') if (&debug('smtp'));
    return 0;
}

##### SMTP SESSION CLOSING #####
#
# smtp_close()
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub smtp_close() {
#   @Status =();
    return 0 unless ($SMTPd);
    return 0 unless ($Smtp_opened);
    $Smtp_opened = 0;
    im_notice("closing SMTP session.\n");
    return 1 if (&tcp_command(\*SMTPd, 'QUIT', ''));
    close(SMTPd);
    return 0;
}

##### SMTP TRANSACTION MANAGEMENT #####
#
# smtp_transaction(server_list, bcc_flag, part, total)
#	server_list:
#	bcc_flag: send message in "bcc" style
#	part: part number to be sent in partial message mode
#	total: total number of partial messages
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub smtp_transaction($$$$$$) {
    my($servers, $Header, $Body, $bcc, $part, $total) = @_;
    my $rc;
    my $fatal_error = 0;
    
    for (my $i = 0; $i <= $#$servers; $i++) {
	$rc = smtp_transact_sub(@$servers[$i], $servers, $Header, $Body,
				$bcc, $part, $total);
	return 0 if ($rc == 0);

	if (($rc < 0 && !$main::Smtp_fatal_next) || $#$servers == $i) {
	    # fatal error or the last server
	    $fatal_error = 1;
	}
	
	# close and try the next server if TEMPFAIL
	smtp_close() unless ($fatal_error);

	log_action($Esmtp_flag ? 'esmtp' : 'smtp', get_cur_server(),
		   join(',', @main::Recipients),
		   $fatal_error ? 'failed' : 'skipped', command_response());
	im_warn($SmtpErrTitle . join("\n", command_response()) . "\n");
	$SmtpErrTitle = '';

	return $rc if ($fatal_error);
    }
    return $rc;
}

##### SMTP TRANSACTION MANAGEMENT SUBROUTUNE #####
#
# smtp_transact_sub(server, server_list, header, body, bcc_flag, part, total)
#	server: current server
#	server_list:
#	header:
#	body:
#	bcc_flag: send message in "bcc" style
#	part: part number to be sent in partial message mode
#	total: total number of partial messages
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub smtp_transact_sub($$$$$$$) {
    my($server, $server_list, $Header, $Body, $bcc, $part, $total) = @_;
    my($i, $rc, $fail, @fatal, $msg_size, $btype);
    return $rc if ($rc = smtp_open($server, $server_list, 1));
    if ($ESMTP{'8BITMIME'} && $main::Has_8bit_body && !$main::do_conv_8to7) {
        $btype = ' BODY=8BIT';
    } else {
        $btype = '';
    }
    if ($ESMTP{'SIZE'}) {
	$msg_size = &message_size($Header, $Body, $part);
	$rc = &tcp_command(\*SMTPd,
	  "MAIL FROM:<$main::Sender> SIZE=$msg_size$btype", '');
    } else {
	$rc = &tcp_command(\*SMTPd, "MAIL FROM:<$main::Sender>$btype", '');
    }
    return $rc if ($rc);
    $fail = 0;
    my($rec);
    for ($i = 0; $i <= $#main::Recipients; $i++) {
	$rec = $main::Recipients[$i];
	if ($bcc) {
	next if ($rec =~ /<.+>/);
	    if ($ESMTP{'DSN'} && $main::Dsn_success_report) {
		$rc = &tcp_command(\*SMTPd,
		  "RCPT TO:<$rec> NOTIFY=SUCCESS", '');
	    } else {
		$rc = &tcp_command(\*SMTPd, "RCPT TO:<$rec>", '');
	    }
	    my(@resp) = &command_response;
	    if ($rc) {
		push(@fatal, @resp);
	    }
	    $fail = $rc if ($fail != -1 && $rc);
	    $Status[$i] = $resp[0];
	} else {
	    next if ($rec !~ /<.+>/);
	    if ($ESMTP{'DSN'} && $main::Dsn_success_report) {
		$rc = &tcp_command(\*SMTPd, "RCPT TO:$rec NOTIFY=SUCCESS", '');
	    } else {
		$rc = &tcp_command(\*SMTPd, "RCPT TO:$rec", '');
	    }
	    my(@resp) = &command_response;
	    if ($rc) {
		push(@fatal, @resp);
	    }
	    $fail = $rc if ($fail != -1 && $rc);
	    $Status[$i] = $resp[0];
	}
    }
    if ($fail) {
	&set_command_response(@fatal);
	return $fail;
    }
    return $rc if ($rc = &tcp_command(\*SMTPd, 'DATA', ''));
    select (SMTPd); $| = 0; select (STDOUT);
    &set_crlf("\r\n");
    if ($bcc) {
	return 1 if (&put_mimed_bcc(\*SMTPd, $Header, $Body, 'smtp', 1,
	    $part, $total) < 0);
    } else {
	if ($part == 0) {
	    return 1 if (&put_header(\*SMTPd, $Header, 'smtp', 'all') < 0);
	    return 1 if (&put_body(\*SMTPd, $Body, 1, 0) < 0);
	} else {
	    return 1 if (&put_mimed_partial(\*SMTPd, $Header, $Body,
	      'smtp', 1, $part, $total) < 0);
	}
    }
    select (SMTPd); $| = 1; select (STDOUT);
    return $rc if ($rc = &tcp_command(\*SMTPd, '.', ''));
    my(@resp) = &command_response;
    &log_action($Esmtp_flag ? 'esmtp' : 'smtp', &get_cur_server(),
		join(',', @main::Recipients), 'sent', @resp);
    $main::Info .= "Delivery successful for the following recipient(s):\n";
    for ($i = 0; $i <= $#main::Recipients; $i++) {
	if ($Status[$i] =~ /^2/) {
	    $main::Info .= "\t$main::Recipients[$i]\n";
	}
    }
    return 0;
}

##### SMTP TRANSACTION MANAGEMENT FOR RETURN ERROR NOTIFY #####
#
# smtp_transaction_for_error_notify(server, server_list, header, body)
#	server: current server
#	server_list:
#	header:
#	body:
#	return value:
#		 0: success
#		 1: recoverable error (should be retried)
#		-1: unrecoverable error
#
sub smtp_transaction_for_error_notify($$$$) {
    my($server, $servers, $Header, $Body) = @_;
    my($rc, @prev_rcpt, @prev_stat);
    @prev_rcpt = @main::Recipients;
    @prev_stat = @Status;
    @main::Recipients = ($main::Sender);
    return $rc if ($rc = &smtp_open($server, $servers, 0));
    return $rc if ($rc = &tcp_command(\*SMTPd, "MAIL FROM:<>", ''));
    return $rc if ($rc = &tcp_command(\*SMTPd, "RCPT TO:<$main::Sender>", ''));
    return $rc if ($rc = &tcp_command(\*SMTPd, 'DATA', ''));
    select (SMTPd); $| = 0; select (STDOUT);
    &set_crlf("\r\n");
    &put_mimed_error_notify(\*SMTPd, $Header, $Body, \@prev_rcpt, \@prev_stat,
	$Esmtp_flag ? 'esmtp' : 'smtp', &get_cur_server, 1, &get_session_log);
    select (SMTPd); $| = 1; select (STDOUT);
    return $rc if ($rc = &tcp_command(\*SMTPd, '.', ''));
    my(@resp) = &command_response;
    &log_action($Esmtp_flag ? 'esmtp' : 'smtp', &get_cur_server(),
		join(',', @main::Recipients), 'sent', @resp);
    return 0;
}

1;

__END__

=head1 NAME

IM::Smtp - SMTP handler

=head1 SYNOPSIS

 use IM::Smtp;

 $return_code = &smtp_open(current_server, server_list, log_flag);
 $return_code = &smtp_close(socket, savehist_flag);
 $return_code = &smtp_transaction(bcc_flag, part_current, part_total);
 $return_code = &smtp_transaction_for_error_notify;

=head1 DESCRIPTION

The I<IM::Smtp> module handles SMTP.

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
