# -*-Perl-*-
################################################################
###
###			      Message.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Oct 28, 2003
###

my $PM_VERSION = "IM::Message.pm version 20031028(IM146)";

package IM::Message;
require 5.003;
require Exporter;

use IM::Util;
use IM::Address qw(extract_addr replace_addr fetch_addr);
use IM::Alias qw(alias_lookup hosts_completion);
use IM::Config qw(use_xdispatcher);
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(
	read_header
	message_size
	put_header
	read_body
	put_body

	rewrite_header
	rewrite_resend_header
	body_qp_encode
	body_base64_encode
	put_mimed_bcc
	put_mimed_partial
	put_mimed_error_notify
	set_crlf
	crlf

	gen_message_id
	gen_date
	header_value
	add_header
	kill_header
	kill_empty_header
	sort_header
);

use vars qw($First_body_line $First_part_mid
	    $bcc_mid $crlf_char
	    @Week_str @Month_str $Cur_time
	    %Mid_hist $Prev_mid_time $Mid_rnd_hist);
@Week_str = qw(Sun Mon Tue Wed Thu Fri Sat);
@Month_str = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub cur_time($) {
    my $part = shift;
    return $Cur_time if ($Cur_time && $part == 0);
    return $Cur_time = time;
}

##### READ HEADER #####
#
# read_header(channel, header, dist_append_flag)
#	channel: socket/file descriptor to write out
#	dist_append_flag: as redistribution headers if true
#	return value:
#	  0: success
#	 -1: failure
#
sub read_header(*$$) {
    local *CHAN = shift;
    my($Header, $dist_append) = @_;
    my($inheader, $line) = (1, '');

    $First_body_line = '';
    local $_ = <CHAN>;
    unless ($_) {
	$inheader = 0;
	$First_body_line = '' unless ($dist_append);
    } elsif (!$main::Smtp_input_mode && $_ =~ /^From /) {
	$_ = <CHAN>;		# skip UNIX From_ line
    }
    while ($inheader) {
	$line = $_;
	if ($main::Draft_message && $line =~ /^-+$/) {
	    $inheader = 0;
	    $First_body_line = "\n" unless ($dist_append);
	    $line = '';
	    last;
	}
	if ($line !~ /^[\w-]+:/) {
	    $inheader = 0;
	    $First_body_line = $line unless ($dist_append);
	    $line = '';
	    last;
	}
	if ($dist_append) {
	    if ($line !~ /^Resent-(To|Cc|Bcc|Dcc|Fcc|Reply-To|Sender|From):/i) {
		$line =~ /^([\w-]+:)/;
		im_err("Remove $1 from re-send information.\n");
		return -1;
	    }
	}
	while (<CHAN>) {
	    if (/^[ \t]/) {
		    $line .= $_;
	    } else {
		    last;
	    }
	}
	push (@$Header, $line) if ($line);
    }
    return 0;
}

##### REWRITE HEADER ON ADDRESSES #####
#
# rewrite_header(header)
#	header: reference to a message header array
#	return value:
#	  -1: failed
#	   0: success
#
sub rewrite_header($) {
    my $Header = shift;
    my($i, $val);
    local $_;

    my $e = $#$Header;	# do not evaluate in the loop
    for ($i = 0; $i <= $e; $i++) {
	$_ = $$Header[$i];
	if (/^(Resent-)?(To|Cc|Bcc|Dcc):\s*(.*)/is) {
	    &add_header($Header, 0, " ORIGINAL $1$2", $3);
	    $val = &rewrite_addr_list($Header, 0, $3, !$main::Obey_MTA_domain);
	    return -1 if ($val eq '');
	    $$Header[$i] = "$1$2: $val";
	} elsif (/^(Resent-)?(From|Reply-To|Errors-To|Return-Receipt-To):\s*(.*)/is) {
	    &add_header($Header, 0, " ORIGINAL $1$2", $3);
	    $val = &rewrite_addr_list($Header, 1, $3, !$main::Obey_MTA_domain);
	    return -1 if ($val eq '');
	    $$Header[$i] = "$1$2: $val";
	} elsif (/^(B?Newsgroups):(.*)/is) {
	    # strip spaces off
	    my $fieldname = $1;
	    ($val = $2) =~ s/[ \t]//g;
	    $$Header[$i] = "$fieldname: $val";
	} elsif (/^([\w-]+):\s*(\S.*)/s) {
	    $$Header[$i] = "$1: $2";
	}
    }
    return 0;
}

##### REWRITE ADDRESS LIST #####
#
# rewrite_addr_list(header, sender_flag, address_list, append_default)
#	header: reference to a message header array
#	sender_flag: rewrite as a sender's address
#	address_list: address list to be rewrited
#	append_default: append default domain name for local names if true
#	return value: rewritten addresses (NULL if error)
#
sub rewrite_addr_list($$$;$) {
    my($Header, $sender_flag, $addr_list, $def_append) = @_;
    my($line, $ret, $addr, $a, $b, $err);

    $addr_list =~ s/^\s+//;
    $addr_list =~ s/\s+$//;
#   $addr_list =~ s/\n[ \t]+/ /g;	# XXX
    while ($addr_list ne '') {
	($addr, $addr_list) = &fetch_addr($addr_list, 0);
	return '' if ($addr eq '');
	$a = &extract_addr($addr);
	if ($a =~ /^(.+)(:[^;]*;)$/) {	# YYY
#	    &expn_group(0, "$1$2");
	    &add_header($Header, 0, $main::Resend_prefix.'Dcc', "$1$2");
	    $addr = "$1:;";
	} else {
	    if ($addr =~ /^\@MYSELF\@/i || $addr =~ /^\@ME\@/i) {
		$addr = $main::Sender;
	    }
	    if ($a !~ /[\@%!:]/ && ($b = alias_lookup($a)) ne '') {
## if ISO2022JP
		if ($main::Iso2022jp_code_conversion) {
		    require IM::Japanese;
		    import IM::Japanese qw(conv_iso2022jp);

		    $b = &conv_iso2022jp($b);
		}
		if ($main::Iso2022jp_header_mime_conv) {
		    require IM::Iso2022jp;
		    import IM::Iso2022jp qw(struct_iso2022jp_mimefy);

		    my $bb = &struct_iso2022jp_mimefy($b);
		    $b = $bb if ($bb ne '');
		}
## endif
		if ($addr_list) {
		    $addr_list = "$b,$addr_list";
		} else {
			$addr_list = $b;
		}
		next;
	    }
	    if ($a !~ /[\@%!:]/o) {
		if ($sender_flag && $def_append
		    && $main::Default_from_domain_name) {
		    $b = "$a\@$main::Default_from_domain_name";
		    $addr = &replace_addr($addr, $a, $b);
		} elsif ($def_append && $main::Default_to_domain_name) {
		    $b = "$a\@$main::Default_to_domain_name";
		    $addr = &replace_addr($addr, $a, $b);
		}
	    } elsif ($b = hosts_completion($a,$main::Cmpl_with_gethostbyname)) {
		$addr = &replace_addr($addr, $a, $b);
	    }
	}
	$line .= ',' if ($line);
	im_debug("rewrite: $a => $addr\n") if (&debug('alias'));
	$line = hdr_cat($line, $addr);
	$addr_list =~ s/^\s*//;
    }
    return "$line\n";
}

##### REWRITE HEADER FOR RESEND #####
#
# rewrite_resend_header()
#	return value: none
#
sub rewrite_resend_header($) {
    my $Header = shift;

    my $i;
    for ($i = 0; $i <= $#$Header; $i++) {
	if ($$Header[$i] =~ /^Resent-/i) {
	    $$Header[$i] = "Prev-$$Header[$i]";
	}
    }
}

##### PUT HEADER TO SMTP CHANNEL #####
#
# put_header(channel, header, protocol, field_selection)
#	channel: socket/file descriptor to write out
#	field_selection: ext/int header specification in partial message mode
#	protocol:
#	return value:
#		 0: success
#		-1: failure
#
sub put_header(*$$$) {
    local *CHAN = shift;
    my($Header, $proto, $sel) = @_;
    my($line, $del, $s);
    my $crlf = &crlf;

    im_debug("entering put_header ($sel)\n")
      if (&debug('header') || &debug('put'));
    hdr: foreach (@$Header) {
	$line = $_;
	next if ($line =~ /^ KILLED /);
	if ($line =~ /^ ORIGINAL /) {
	    next if ($sel ne 'original');
	    if ($line =~ /^ ORIGINAL [BDF]cc:/i) {
		$line =~ s/^ ORIGINAL //;
	    } else {
		next;
	    }
	}
	if ($sel =~ /^partial:/) {
	    if ($line =~ /^(Subject|Mime-Version|Message-Id|Encrypted|Lines):/i
	          || $line =~ /^Content-/i) {
		next if ($sel =~ /:ext$/);
	    } else {
		next if ($sel =~ /:int$/);
	    }
	}
	if ($proto =~ /smtp/i) {
	    foreach $del (@main::Del_headers_on_mail) {
		next hdr if ($line =~ /^$del:/i);
	    }
	    next if ($line =~ /^BNewsgroups:/i);
	    $line =~ s/^Newsgroups:/X-Newsgroups:/i;
	}
	if ($proto =~ /nntp/i) {
	    foreach $del (@main::Del_headers_on_news) {
		next hdr if ($line =~ /^$del:/i);
	    }
	    next hdr if ($line =~ /Message-Id:/i && $main::NoMsgIdForNews);
	    if ($main::Obey_MTA_domain
	      && ($line =~ /^(From|Sender|Reply-To):\s*(.*)/i)) {
		my $val = &rewrite_addr_list($Header, 1, $2, 1);
		return -1 if ($val eq '');
		$line = "$1: $val";
	    }
	    $line =~ s/^Sender:/Originator:/i;
	    $line =~ s/^BNewsgroups:/Newsgroups:/i;
	}
	$line .= "\n" if ($line !~ /\n$/);
	$line =~ s/\r?\n/\r\n/g if ($crlf eq "\r\n");
	im_debug("|$line") if (&debug('header') || &debug('put'));
	return -1 unless (print CHAN "$line");
    }
    if ($proto =~ /nntp/i && !&header_value($Header, 'Path')) {
#	return -1 unless (print CHAN "Path: $main::Login$crlf");
	return -1 unless (print CHAN "Path: not-for-mail$crlf");
    }
    im_debug("put_header finished: no error\n")
      if (&debug('header') || &debug('put'));
    return 0;
}

##### READ BODY #####
#
# read_body(channel, body, hidden_dot, term_dot)
#	channel: socket/file descriptor to write out
#	hidden_dot: hidden dot algorithm is used if true
#	term_dot: terminating dot protocol is used if true
#	return value: none
#
sub read_body(*$$$) {
    local *CHAN = shift;
    my($Body, $hidden_dot, $term_dot) = @_;
    local $_;
    @$Body = ();

    if ($hidden_dot || $term_dot) {
	return if ($First_body_line =~ /^\.[\r\n]/);
	$First_body_line =~ s/^\.\././ if ($hidden_dot);
    }
    if ($First_body_line) {
	if ($First_body_line ne "\n") {
	    push (@$Body, "\n");
	}
	push (@$Body, $First_body_line);
	while (<CHAN>) {
	    if ($hidden_dot || $term_dot) {
		last if (/^\.[\r\n]/);
		s/^\.\././ if ($hidden_dot);
	    }
	    push (@$Body, $_);
	}
	$First_body_line = "\n";	# XXX
    }
}

##### CONVERT BODY INTO QUOTED-PRINTABLE ENCODING #####
#
# body_qp_encode(Body)
#	content: pointer to body content line list
#	return value: none
#
sub body_qp_encode($) {
    my $Body = shift;
    my($i, $line, $pos);

    for ($i = 0; $i <= $#$Body; $i++) {
	$line = $$Body[$i];
	$line .= "\n" if ($line !~ /\n$/);	# XXX
	$line =~ s/([\000-\010\013-\037=\177-\377])/sprintf("=%02X", unpack ("C", $1))/ge;
	$line =~ s/ \n$/=20\n/;
	$line =~ s/\t\n$/=09\n/;
	$line =~ s/^\.\n$/=2e\n/;
	$line =~ s/^From /From=20/;
	while (!$main::NoFolding && (length($line) > $main::Folding_length+3)) {
	    # XXX line splitting
	    for ($pos = $main::Folding_length; $pos < $main::Folding_length+3;
	      $pos++) {
		last if (substr($line, $pos, 1) eq "=");
	    }
	    (my $tmp, $line) = unpack("a$pos a*", $line);
	    splice(@$Body, $i, 0, $tmp . "=");
	    $i++;
	}
	$$Body[$i] = $line;
    }
}

##### CONVERT BODY INTO BASE64 ENCODING #####
#
# body_base64_encode(content)
#	content: pointer to body content line list
#	return value: none
#
sub body_base64_encode($) {
    my $Body = shift;
    my $line = '';
    my($i, $tmp, @Body_tmp);

    require IM::EncDec && import IM::EncDec qw(b_encode_string);

    for ($i = 0; $i <= $#$Body; $i++) {
	$line .= $$Body[$i];
	$line .= "\n" if ($line !~ /\n$/);
#	$line =~ s/\r?\n?$/\r\n/;
	next if (length($line) < 54 && $i <= $#$Body);
	($tmp, $line) = unpack('a54 a*', $line);
	push(@Body_tmp, &b_encode_string($tmp));
    }
    while ($line ne '') {
	($tmp, $line) = unpack('a54 a*', $line);
	push(@Body_tmp, &b_encode_string($tmp));
    }
    @$Body = @Body_tmp;
    @Body_tmp = ();	# XXX
}

##### PUT BODY TO SMTP CHANNEL #####
#
# put_body(channel, body, hidden_dot, part)
#	channel: socket/file descriptor to write out
#	hidden_dot: hidden dot algorithm is used if true
#	part: part number to be sent in partial message mode
#	return value:
#		 0: success
#		-1: failure
#
sub put_body(*$$$) {
    local *CHAN = shift;
    my($Body, $hidden_dot, $part) = @_;
    my($start, $end, $i, $line);
    my $crlf= &crlf;

    if ($part == 0) {
	$start = 0;
	$end = $#$Body;
    } else {
	$start = $main::Lines_to_partial * ($part - 1);
	$end = $main::Lines_to_partial * $part;
	$start++ if ($part > 1);
	$end = $#$Body if ($end > $#$Body);
    }
    im_debug("entering put_body\n") if (&debug('put'));
    for ($i = $start; $i <= $end; $i++) {
	$line = $$Body[$i];
	$line .= "\n" if ($line !~ /\n$/);
	$line =~ s/\r?\n/\r\n/g if ($crlf eq "\r\n");
	$line =~ s/^\./../ if ($hidden_dot);
	im_debug("|$line") if (&debug('put'));
	return -1 unless (print CHAN $line);
#	im_debug($line);
    }
    im_debug("put_body finished: no error\n") if (&debug('put'));
    return 0;
}

##### GENERATE MIMED-BCC #####
#
# put_mimed_bcc(channel, header, body, protocol, hidden_dot, part, total)
#	channel: socket/file descriptor to write out
#	header: message header
#	bory: message body
#	hidden_dot: hidden dot algorithm is used if true
#	part: part number to be sent in partial message mode
#	total: total number of partial messages
#	return value: (XXX)
#		 0: success
#		-1: failure
#
sub put_mimed_bcc(*$$$$$$) {
    local *CHAN = shift;
    my($Header, $Body, $proto, $hidden_dot, $part, $total) = @_;
    my $subj;
    my $crlf = &crlf;

    my $frm = &header_value($Header, 'Resent-From');
    if ($frm eq '') {
	$frm = &header_value($Header, 'From');
	if ($frm eq '') {
	    $frm = $main::Sender_line;
	}
    }
    return -1 unless (print CHAN "From: $frm$crlf");
    if (&extract_addr($frm) ne $main::Sender) {
	print CHAN "Sender: $main::Sender_line$crlf";
    }
    print CHAN "To: blind-copy-recipients:;$crlf";
    if (use_xdispatcher()) {
	print CHAN "X-Dispatcher: $main::VERSION$crlf";
    }
    if (($subj = &header_value($Header, 'Subject')) ne '') {
	print CHAN "Subject: Bcc: $subj$crlf";
    } else {
	print CHAN "Subject: Blind Carbon Copy$crlf";
    }
    if ($main::Generate_message_id) {
	$main::Cur_mid = &gen_message_id(0);
	print CHAN "Message-Id: $main::Cur_mid$crlf";
	$First_part_mid = $main::Cur_mid if ($part == 1);
    }
    print CHAN 'Date: ' . &gen_date(1) . $crlf
	if ($main::Generate_date);
    if ($part) {
	$bcc_mid = &gen_message_id(0) unless ($bcc_mid); # XXX
	print CHAN "Mime-Version: 1.0$crlf";
	print CHAN "Content-Type: Message/partial;$crlf";
	printf CHAN "\tid=\"%s\"; number=%d; total=%d$crlf",
	    $bcc_mid, $part, $total;
	print CHAN "Content-Description: part $part of $total$crlf";
	print CHAN "References: $First_part_mid$crlf"
	    if ($part > 1);
	print CHAN $crlf;
	print CHAN "Message-Id: $bcc_mid$crlf" if ($part == 1);
    }
    if ($part <= 1) {
	print CHAN "Mime-Version: 1.0$crlf";
	print CHAN "Content-Type: Message/rfc822$crlf";
	print CHAN $crlf;

	return -1 if (&put_header(\*CHAN, $Header, $proto, 'all') < 0);
    }
    return -1 if (&put_body(\*CHAN, $Body, $hidden_dot, $part) < 0);
    return 0;
}

##### GENERATE PARTIAL/MIME #####
#
# put_mimed_partial(channel, header, body, protocol, hidden_dot, part, total)
#	channel: socket/file descriptor to write out
#	header: message header
#	bory: message body
#	hidden_dot: hidden dot algorithm is used if true
#	part: part number to be sent in partial message mode
#	total: total number of partial messages
#	return value: (XXX)
#		 0: success
#		-1: failure
#
sub put_mimed_partial(*$$$$$$) {
    local *CHAN = shift;
    my($Header, $Body, $proto, $hidden_dot, $part, $total) = @_;
    my $crlf = &crlf;

    return -1 if (&put_header(\*CHAN, $Header, $proto, 'partial:ext') < 0);
    if ($main::Generate_message_id) {
	$main::Cur_mid = &gen_message_id($part);
	print CHAN "Message-Id: $main::Cur_mid$crlf";
	$First_part_mid = $main::Cur_mid if ($part == 1);
    }
    my $subj = &header_value($Header, 'Subject');
    print CHAN "Subject: $subj (part $part of $total)$crlf";
    print CHAN "Mime-Version: 1.0$crlf";
    print CHAN "Content-Type: Message/partial;$crlf";
    printf CHAN "\tid=\"%s\"; number=%d; total=%d$crlf",
	&header_value($Header, 'Message-Id'), $part, $total;
    print CHAN "Content-Description: part $part of $total$crlf";
    print CHAN "References: $First_part_mid$crlf" if ($part > 1);
    print CHAN "$crlf";

    if ($part == 1) {
	return -1 if (&put_header(\*CHAN, $Header, $proto, 'partial:int') < 0);
    }
    return -1 if (&put_body(\*CHAN, $Body, $hidden_dot, $part) < 0);
    return 0;
}

##### GENERATE MIMED ERROR NOTIFY #####
#
# put_mimed_error_notify(channel, header, body, recipients, status, protocol,
#			server, hidden_dot, session_log)
#	channel: socket/file descriptor to write out
#	header: message header
#	bory: message body
#	recipients:
#	status:
#	protocol:
#	server:
#	hidden_dot: hidden dot algorithm is used if true
#	session_log: logged messaged when error occurs
#	return value: (XXX)
#		 0: success
#		-1: failure
#
sub put_mimed_error_notify(*$$$$$$$$;$) {
    local *CHAN = shift;
    my($Header, $Body, $Recp, $Stat, $proto, $server,
       $hidden_dot, $session_log, $part) = @_;    # XXX: $part missing?
    my $subj;
    my $crlf = &crlf;
    my $boundary;

    return -1 unless (print CHAN "To: $main::Sender_line$crlf");
    print CHAN "From: Imput-Error-Report$crlf";
    if (use_xdispatcher()) {
	print CHAN "X-Dispatcher: $main::VERSION$crlf";
    }
    if (($subj = &header_value($Header, 'Subject')) ne '') {
	print CHAN "Subject: Returned message: $subj$crlf";
    } else {
	print CHAN "Subject: Returned message$crlf";
    }
    if ($main::Generate_message_id) {
	$main::Cur_mid = &gen_message_id(0);
	print CHAN "Message-Id: $main::Cur_mid$crlf";
    }
    print CHAN 'Date: ' . &gen_date(1) . $crlf
	if ($main::Generate_date);
    print CHAN "Mime-Version: 1.0$crlf";
    print CHAN "Content-Type: Multipart/report;$crlf";
    print CHAN "\treport-type=delivery-status;$crlf";
    $boundary = &gen_message_id(0);
    $boundary =~ y/<@>/-_-/;
    print CHAN "\tboundary=\"$boundary\"$crlf";
    print CHAN "Precedence: junk$crlf";
    print CHAN $crlf;

    print CHAN "This is a MIME-encapsulated message$crlf$crlf";
    print CHAN "--$boundary$crlf";
    print CHAN $crlf;
    print CHAN "Your message was not delivered successfully.$crlf";
    my $errlog = im_saved_errors();
    if ($errlog) {
	print CHAN $crlf;
	print CHAN "Reason:$crlf";
	print CHAN "$errlog$crlf";
    }
    if ($main::Info) {
	print CHAN $crlf;
	print CHAN "$main::Info$crlf";
    }
#   my $session_log = &get_session_log();
    if ($session_log) {
	print CHAN $crlf;
	print CHAN "$session_log$crlf";
    }
    if ($#$Recp >= 0) {
	require Sys::Hostname && import Sys::Hostname;

	# host information
	my $myhostname = hostname();
	unless ($myhostname =~ /\./) {
	    my($h) = gethostbyname($myhostname);
	    $myhostname = $h if ($h);
	}

	print CHAN "--$boundary$crlf";
	print CHAN "Content-Type: message/delivery-status$crlf";
	print CHAN $crlf;
	print CHAN "Reporting-MTA: dns; $myhostname$crlf";
#	print CHAN "Arrival-Date: (startup time)$crlf";

	my $i;
	for ($i = 0; $i <= $#$Recp; $i++) {
	    print CHAN $crlf;
	    print CHAN "Final-Recipient: rfc822; $$Recp[$i]$crlf";
	    if ($$Stat[$i] =~ /^2/) {
#		print CHAN "Action: relayed$crlf";
		print CHAN "Action: failure$crlf";
		print CHAN "Status: 5.1.5$crlf";	# XXX
	    } else {
		print CHAN "Action: failure$crlf";
		print CHAN "Status: 5.1.1$crlf";	# XXX
	    }
	    print CHAN "Remote-MTA: $server$crlf";
	    print CHAN "Diagnostic-Code: smtp; $$Stat[$i]$crlf";
	}
    }
    if ($#$Header >= 0 || $#$Body >= 0) {
	print CHAN "--$boundary$crlf";
	print CHAN "Content-Type: Message/rfc822$crlf";
	print CHAN $crlf;
	return -1 if (&put_header(\*CHAN, $Header, $proto, 'original') < 0);
	return -1 if (&put_body(\*CHAN, $Body, $hidden_dot, $part) < 0);
	print CHAN $crlf;	# a linebreak is needed here
    }
    print CHAN "--$boundary--$crlf";
    return 0;
}

##### GET SIZE OF MESSAGE #####
#
# message_size(header, body, part)
#	header: reference to a message header array
#	body: reference to a message body array
#	return value: size of whole message
#
sub message_size($$$) {
    my($Header, $Body, $part) = @_;
    my($start, $end, $i, $size);

    if ($part == 0) {
	$start = 0;
	$end = $#$Body;
    } else {
	$start = $main::Lines_to_partial * ($part - 1);	# XXX?? main?
	$end = $main::Lines_to_partial * $part - 1; # XXX?? main?
	$end = $#$Body if ($end > $#$Body);
    }
    $size = 0;
    for ($i = 0; $i <= $#$Header; $i++) {
	$size += length($$Header[$i]) unless ($$Header[$i] =~ /^ KILLED /);
    }
    for ($i = $start; $i <= $end; $i++) {
	$size += length($$Body[$i]);
    }
    return $size;
}

sub set_crlf($) {
    $crlf_char = shift;
}

sub crlf() {
    $crlf_char;
}

##### GENERATE A MESSAGE-ID CHARACTER STRING #####
#
# gen_message_id(part)
#	part: part number of partial messages (for reuse)
#	return value: a unique message-id string
#
sub gen_message_id($) {
    my $part = shift;
    return $Mid_hist{$part} if ($part > 0 && $Mid_hist{$part});
    my($tm_sec, $tm_min, $tm_hour, $tm_mday, $tm_mon, $tm_year)
	= localtime(&cur_time($part));
    my($mid_time) = sprintf("%d%02d%02d%02d%02d%02d",
	$tm_year+1900, $tm_mon+1, $tm_mday, $tm_hour, $tm_min, $tm_sec);
    my($mid_rnd) = sprintf("%c", 0x41 + rand(26));
    if ($Prev_mid_time eq $mid_time) {
	while ($mid_rnd =~ /[$Mid_rnd_hist]/) {
	    $mid_rnd = sprintf("%c", 0x41 + rand(26));
	}
	$Mid_rnd_hist .= $mid_rnd;
    } else {
	$Prev_mid_time = $mid_time;
	$Mid_rnd_hist = $mid_rnd;
    }
    if ($main::Message_id_PID) {
	$mid_rnd = "-".$$.$mid_rnd;
    }
    my $mid_user;
    if ($main::Message_id_UID) {
	$mid_user = $<;
    } else {
	$mid_user = $main::Login;
    }
    my($mid)
      = "<$mid_time$mid_rnd.$mid_user\@$main::Message_id_domain_name>";
    $Mid_hist{$part} = $mid if ($part > 0);
    return $mid;
}

##### GANARATE A DATE CHARACTER STRING #####
#
# gen_date(format)
#	format:
#		0 = "DD MMM YYYY HH:MM:SS TZ" (mainly for news)
#		1 = "WWW, DD MMM YYYY HH:MM:SS TZ"
#		2 = "WWW MMM DD HH:MM:SS YYYY" (mainly for UNIX From)
#	return value: date string generated with current time
#
sub gen_date($) {
    my $format = shift;
    my($tm_sec, $tm_min, $tm_hour, $tm_mday, $tm_mon, $tm_year,
       $tm_wk, $tm_yday, $tm_isdst, $tm_tz);
    if ($main::NewsGMTdate && $main::News_flag) {
	($tm_sec, $tm_min, $tm_hour, $tm_mday, $tm_mon, $tm_year,
	    $tm_wk, $tm_yday) = gmtime(&cur_time(0));
	$tm_tz = 'GMT';
    } else {
	($tm_sec, $tm_min, $tm_hour, $tm_mday, $tm_mon, $tm_year,
	  $tm_wk, $tm_yday, $tm_isdst) = localtime(&cur_time(0));
	my $off;
	if ($ENV{'TZ'} =~ /^([A-Z]+)([-+])?(\d+)(?::(\d\d)(?::\d\d)?)?([A-Z]+)?(?:([-+])?(\d+)(?::(\d\d)(?::\d\d)?)?)?/) {
	    $tm_tz = $1;
	    $off = $3 * 60 + $4;
	    $off = -$off if ($2 ne '-');
	    if ($tm_isdst && $5 ne '') {
		$tm_tz = $5;
		if ($7 ne '') {
		    $off = $7 * 60 + $8;
		    $off = -$off if ($6 ne '-');
		} else {
		    $off += 60;
		}
	    }
	} else {
	    my($gm_sec, $gm_min, $gm_hour, $gm_mday, $gm_mon,
	       $gm_year, $gm_wk, $gm_yday) = gmtime(&cur_time(0));
	    $off = ($tm_hour - $gm_hour) * 60 + $tm_min - $gm_min;
	    if ($tm_year < $gm_year) {
		$off -= 24 * 60;
	    } elsif ($tm_year > $gm_year) {
		$off += 24 * 60;
	    } elsif ($tm_yday < $gm_yday) {
		$off -= 24 * 60;
	    } elsif ($tm_yday > $gm_yday) {
		$off += 24 * 60;
	    }
	}
	my $tzc = " ($tm_tz)" if ($tm_tz ne '');
	if ($off == 0) {
	    $tm_tz = 'GMT';
	} elsif ($off > 0) {
	    $tm_tz = sprintf("+%02d%02d%s", $off/60, $off%60, $tzc);
	} else {
	    $off = -$off;
	    $tm_tz = sprintf("-%02d%02d%s", $off/60, $off%60, $tzc);
	}
    }
    if ($format == 0) {
	return sprintf("%02d %s %d %02d:%02d:%02d %s", $tm_mday,
	  $Month_str[$tm_mon], $tm_year+1900, $tm_hour, $tm_min,
	  $tm_sec, $tm_tz);
    } elsif ($format == 1) {
	return sprintf("%s, %02d %s %d %02d:%02d:%02d %s", $Week_str[$tm_wk],
	  $tm_mday, $Month_str[$tm_mon], $tm_year+1900, $tm_hour, $tm_min,
	  $tm_sec, $tm_tz);
    } else {
	return sprintf("%s %s %2d %02d:%02d:%02d %s", $Week_str[$tm_wk],
	  $Month_str[$tm_mon], $tm_mday, $tm_hour, $tm_min, $tm_sec,
	  $tm_year+1900);
    }
}

##### GET VALUE OF SPECIFIED HEADER LINE #####
#
# header_value(header, field)
#	header: reference to a message header array
#	field: field name of which value needed
#	return value: value for specified field OR null
#
sub header_value($$) {
    my($Header, $field_name) = @_;
    my $val;
    local $_;

    foreach (@$Header) {
	if (/^$field_name:\s*(.*)/is) {
	    ($val = $1) =~ s/\s*$//;
	    return $val;
	}
    }
    return '';
}

##### ADD A HEADER LINE #####
#
# add_header(header, replace_flag, field_name, field_value)
#	header: reference to a message header array
#	replace_flag: old headers are deleted if true
#	field_name: field name to be entered
#	field_value: field value to be entered with
#	return value: none
#
sub add_header($$$$) {
    my($Header, $replace_flag, $field_name, $field_value) = @_;

    $field_value .= "\n" if ($field_value !~ /\n$/);
    im_debug("adding header> $field_name: $field_value")
	if (&debug('header'));
    if ($replace_flag) {
	my $i;
	for ($i = 0; $i <= $#$Header; $i++) {
	    if ($$Header[$i] =~ /^$field_name:/i) {
		$$Header[$i] = "$field_name: $field_value";
		return;
	    }
	}
    }
    push (@$Header, "$field_name: $field_value");
}

##### KILL SPECIFIED HEADER LINES #####
#
# kill_header(header, field_name, leave_first)
#	header: reference to a message header array
#	field_name: field name to be deleted
#	leave_first: leave the first appeared header line if true
#	return value: none
#
sub kill_header($$$) {
    my($Header, $field_name, $leave_first) = @_;

    my $i;
    for ($i = 0; $i <= $#$Header; $i++) {
	if ($$Header[$i] =~ /^$field_name:/i) {
	    if ($leave_first) {
		$leave_first = 0;
		next;
	    }
	    im_debug("killing $$Header[$i]") if (&debug('header'));
	    $$Header[$i] = " KILLED $$Header[$i]";
	}
    }
}

##### KILL EMPTY HEADER LINES #####
#
# kill_empty_header(header)
#	header: reference to a message header array
#	return value: none
#
sub kill_empty_header($) {
    my $Header = shift;

    my $i;
    for ($i = 0; $i <= $#$Header; $i++) {
	if ($$Header[$i] =~ /^[\w-]+:\s*$/) {
	    im_debug("killing $$Header[$i]") if (&debug('header'));
	    $$Header[$i] = " KILLED $$Header[$i]";
	}
    }
}

##### SORT HEADER LINES #####
#
# sort_header(header, name_list)
#	header: reference to a message header array
#	name_list: leave the first appeared header line if true
#	return value: none
#
sub sort_header($$) {
    my($Header, $name_list) = @_;
    my($i, $label, @tail);

    foreach $label (split(',', $name_list)) {
	for ($i = 0; $i <= $#$Header;) {
	    if ($$Header[$i] =~ /^$label:/i) {
		push (@tail, $$Header[$i]);
		splice(@$Header, $i, 1);
	    } else {
		$i++;
	    }
	}
    }
    push (@$Header, @tail);
}

##### HEADER CONCATINATION #####
#
# hdr_cat(str1, str2)
#	str1: a preceeding header string
#	str2: a header string to be appended to str1
#	return value: a concatinated header string
#
sub hdr_cat($$) {
    my($str1, $str2) = @_;

    if ($str1 eq '' || $str1 =~ /\n[\t ]+$/) {
	return "$str1$str2";
    }
    $str1 =~ /([^\n]*)$/;
    my $l1 = length($1);
    $str2 =~ /^([^\n]*)/;
    my $l2 = length($1);
    if (!$main::NoFolding && ($l1 + $l2 + 1 > $main::Folding_length)) {
	return "$str1\n\t$str2";
    }
    return "$str1 $str2";
}

1;

__END__

=head1 NAME

IM::Message - mail/news message handler

=head1 SYNOPSIS

 use IM::Message;

Subroutines:
read_header
message_size
put_header
read_body
put_body
rewrite_header
rewrite_resend_header
body_qp_encode
body_base64_encode
put_mimed_bcc
put_mimed_partial
put_mimed_error_notify
set_crlf
crlf
gen_message_id
gen_date
header_value
add_header
kill_header
kill_empty_header
sort_header

=head1 DESCRIPTION

The I<IM::Message> module handles mail/news messages.

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
