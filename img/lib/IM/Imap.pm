# -*-Perl-*-
################################################################
###
###			       Imap.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Apr 14, 2000
###

my $PM_VERSION = "IM::Imap.pm version 20000414(IM141)";

package IM::Imap;
require 5.003;
require Exporter;

use IM::Config;
use IM::Util;
use IM::TcpTransaction;
use IM::GetPass;
use IM::MsgStore;
use IM::Scan;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(
    imap_open imap_close imap_select imap_head imap_get imap_put imap_delete
    imap_get_msg imap_spec imap_range2set imap_folder_regname imap_scan_folder 
    imap_open_folders imap_close_folders imap_get_handle imap_get_message
    imap_put_message imap_put_file imap_refile imap_delete_message
);

=head1 NAME

Imap - IMAP handling package

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use vars qw($ImapSeq);
########################
# IMAP access routines #
########################

# imap_open(auth, host, user, pass)
#	return value:
#		 0: success
#		-1: failure
#
sub imap_open ($$$$) {
    my ($auth, $host, $user, $pass) = @_;
    my ($data, $seq, $errmsg);
    my (@host_list) = ($host);
    my $HANDLE;

    $pass = '*' unless ($pass);
    $ImapSeq = 100 unless ($ImapSeq);
    $seq = $ImapSeq++;
    im_notice("opening IMAP session\n");
    &tcp_logging(0);
    $HANDLE = &connect_server(\@host_list, 'imap', 0);
    return -1 unless ($HANDLE);
    my $resp = &send_command($HANDLE, '', '');
    if ($resp !~ /^\* OK/i) {
	im_warn($resp);
	return -1;
    }
    my $failed = 0;
    if ($auth eq 'LOGIN') {
	my ($us, $pw) = ($user, $pass);
	$us =~ s/([\\"])/\\$1/g;	# escape specials
	$us = "\"$us\"";		# quote it
	$pw =~ s/([\\"])/\\$1/g;	# escape specials
	$pw = "\"$pw\"";		# quote it
	$resp = &send_command($HANDLE, "im$seq LOGIN $us $pw",
	  "im$seq LOGIN $us PASSWORD");
	while ($resp !~ /^im$seq/) {
	    if ($resp =~ /^\* NO/i) {
#		$failed = 1;
		$errmsg = $resp;
	    }
	    $resp = &next_response($HANDLE);
	}
    } else {
	require IM::EncDec && import IM::EncDec;
	$resp = &send_command($HANDLE, "im$seq AUTHENTICATE LOGIN", '');
	if ($resp =~ /^\+ (.*)/) {
	    $data = &b_decode_string($1);
	    im_debug("got \"$data\"\n") if (&debug('imap') || &verbose);
	} else {
	    $failed = 1;
	    $errmsg = $resp;
	}
	if (!$failed) {
	    $data = &b_encode_string($user);
	    im_debug("sending $user with base64 encoding.\n")
	      if (&debug('imap') || &verbose);
	    $resp = &send_command($HANDLE, $data,
	      "Base64-encoded-username($user)");
	    if ($resp =~ /^\+ (.*)/) {
		$data = &b_decode_string($1);
		im_debug("got \"$data\"\n") if (&debug('imap') || &verbose);
	    } else {
		$failed = 1;
		$errmsg = $resp;
	    }
	}
	if (!$failed) {
	    $data = &b_encode_string($pass);
	    im_debug("sending PASSWORD with base64 encoding.\n")
	      if (&debug('imap') || &verbose);
	    $resp = &send_command($HANDLE, $data, "Base64-encoded-password");
	}
	while ($resp !~ /^im$seq/) {
	    if ($resp =~ /^\* NO/i) {
#		$failed = 1;
		$errmsg = $resp;
	    }
	    $resp = &next_response($HANDLE);
	}
    }
    if ($resp !~ /^im$seq OK/) {
	$errmsg = $resp;
	$errmsg =~ s/^im$seq\s+NO\s*//i;
	im_warn("$errmsg\n");
	return -1
    }
    return -1 if ($failed);
    return (0, $HANDLE);
}

sub imap_close ($) {
    my ($HANDLE) = @_;
    my ($seq) = $ImapSeq++;
    my $failed = 0;
    if (1) {
	im_notice("closing IMAP session.\n");
	my $resp = &send_command($HANDLE, "im$seq CLOSE", '');
	while ($resp !~ /^im$seq/) {
	    $failed = 1 if ($resp =~ /^\* NO/i);
	    $resp = &next_response($HANDLE);
	}
	return -1 if ($resp !~ /^im$seq OK/);
#	return -1 if ($failed);
	$seq = $ImapSeq++;
	$failed = 0;
    }
    my $resp;
    $resp = &send_command($HANDLE, "im$seq LOGOUT", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    close($HANDLE);
    return 0;
}

sub imap_select ($$$) {
    my ($HANDLE, $mbox, $select) = @_;
    my ($seq) = $ImapSeq++;
    my ($resp, @field);
    if ($select) {
	im_notice("select mbox $mbox and getting number of message.\n");
	$resp = &send_command($HANDLE, "im$seq SELECT $mbox", '');
    } else {
	im_notice("examine mbox $mbox and getting number of message.\n");
	$resp = &send_command($HANDLE, "im$seq EXAMINE $mbox", '');
    }
    my $msgs = -1;
    my $failed = 0;
    while ($resp =~ /^\*/) {
	@field = split(' ', $resp);
	if ($field[1] =~ /^ok$/i) {
	} elsif ($field[1] =~ /^no$/i) {
	    $failed = 1;
	} elsif ($field[1] =~ /^flags$/i) {
	} elsif ($field[2] =~ /^exists$/i) {
	    $msgs = $field[1];
	} elsif ($field[2] =~ /^recent$/i) {
	}
	$resp = &next_response($HANDLE);
    }
    return -1 if ($select && $resp !~ /^im$seq OK \[READ-WRITE\]/i);
    return -1 if (!$select && $resp !~ /^im$seq OK \[READ-ONLY\]/i);
#   return -1 if ($failed);
    return -1 if ($msgs < 0);
    im_notice("$msgs message(s) found.\n");
    return $msgs;
}

sub imap_get ($$) {
    my ($HANDLE, $num) = @_;
    my ($seq) = $ImapSeq++;
    my (@message);
    im_notice("getting message $num.\n");
    my $resp = &send_command($HANDLE, "im$seq UID FETCH $num RFC822", '');
    my $failed = 0;
    if ($resp =~ /^\* \d+ FETCH \((UID $num )?RFC822 \{(\d+)\}/i) {
	my $size = $2;
	alarm(imap_timeout()) unless win95p();
	$! = 0;
	while (<$HANDLE>) {
	    unless (win95p()) {
		alarm(0);
		if ($!) {   # may be channel truoble
		    im_warn("lost connection for FETCH(get).\n");
		    return (-1, 0);
		}
	    }
	    $size -= length($_);
	    s/\r\n$/\n/;
	    im_debug($_) if (&debug('imap'));
	    push (@message, $_);
	    last if ($size <= 0);
	}
	alarm(0) unless win95p();
	$resp = &next_response($HANDLE);
	return (-1, 0) if ($resp !~ /^\)/ &&
			   $resp !~ /^( FLAGS \(.*\)| UID $num)+\)/);
    } elsif ($resp =~ /^im$seq OK/) {
	return (1, 0);
    } else {
	$failed = 1;
	im_warn("UID FETCH command failed.\n");
    }
    $resp = &next_response($HANDLE);
    return (-1, 0) if ($resp !~ /^im$seq OK/);
#   return (-1, 0) if ($failed);
    return (0, \@message);
}

sub imap_head ($$) {
    my ($HANDLE, $num) = @_;
    my ($seq) = $ImapSeq++;
    im_notice("getting header of message $num.\n");
    my $resp = &send_command($HANDLE,
      "im$seq UID FETCH $num (RFC822.SIZE RFC822.HEADER)", '');
    my $failed = 0;
    my (%head);
    undef %head;
    if ($resp =~
    /^\* \d+ FETCH \((UID $num )?RFC822.SIZE (\d+) RFC822.HEADER \{(\d+)\}/i) {
	my ($size, $len) = ($2, $3);
	my $field = '';
	alarm(imap_timeout()) unless win95p();
	$! = 0;
	while (<$HANDLE>) {
	    unless (win95p()) {
		alarm(0);
		if ($!) {   # may be channel truoble
		    im_warn("lost connection for FETCH(head).\n");
		    return (-1, 0);
		}
	    }
	    $len -= length($_);
	    s/\r?\n$//;
	    im_debug("$_\n") if (&debug('imap'));

	    if (/^\s/) {
		s/^\s+//;
		$head{$field} = $head{$field} . $_;
		last if ($len <= 0);
		next;
	    } elsif (/^([^:]+):\s*(.*)/) {
		$field = lc($1);
		$head{$field} = $2;
	    } else {
#		$inheader = 0;
		last if ($len <= 0);
		next;
	    }
	    last if ($len <= 0);
	}
	alarm(0) unless win95p();
#	$head{'bytes:'} = $size;
	$head{'kbytes:'} = int(($size + 1023) / 1024);
	$resp = &next_response($HANDLE);
	return (-1, 0) if ($resp !~ /^\)/ && $resp !~ /^ UID $num\)/);
    } elsif ($resp =~ /^im$seq OK/) {
	return (1, 0);
    } else {
	$failed = 1;
	im_warn("UID FETCH command failed.\n");
    }
    $resp = &next_response($HANDLE);
    return (-1, 0) if ($resp !~ /^im$seq OK/);
#   return (-1, 0) if ($failed);
    return (0, \%head);
}

sub imap_from ($$) {
    my ($HANDLE, $num) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("getting sender information of message $num.\n");
#   my $resp = &send_command($HANDLE,
#     "im$seq UID FETCH $num RFC822.HEADER.LINES (From Date Subject)", '');
    my $resp = &send_command($HANDLE,
      "im$seq UID FETCH $num RFC822.HEADER.LINES (From)", '');
    if ($resp =~ /^\* \d+ FETCH \((UID $num )?RFC822.* \{(\d+)\}/i) {
	my $size = $2;
	my $found = 0;
	my $f;
	alarm(imap_timeout()) unless win95p();
	$! = 0;
	while (<$HANDLE>) {
	    unless (win95p()) {
		alarm(0);
		if ($!) {   # may be channel truoble
		    im_warn("lost connection for FETCH(from).\n");
		    return -1;
		}
	    }
	    $size -= length($_);
	    s/\r\n$/\n/;
	    im_debug($_) if (&debug('imap'));
	    if ($f eq '' && /^From:\s*(.*)/i) {
		$found = 1;
		$f = $1;
	    } elsif (/^\s/ && $found) {
		$f .= $_;
	    } else {
		$found = 0;
	    }
	    last if ($size <= 0);
	}
	alarm(0) unless win95p();
	$f =~ s/\n[ \t]*/ /g;
	$f = '(sender unknown)' unless ($f);
	print "From $f\n";
	$resp = &next_response($HANDLE);
	return -1 if ($resp !~ /^\)/ && $resp !~ /^ UID $num\)/);
    } elsif ($resp =~ /^im$seq OK/) {
	return 1;
    } else {
	$failed = 1;
	im_warn("UID FETCH command failed.\n");
    }
    $resp = &next_response($HANDLE) if ($resp !~ /^im$seq/);
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return 0;
}

sub imap_flags ($$) {
    my ($HANDLE, $num) = @_;
    my $seq = $ImapSeq++;
    my ($flags);
    im_notice("getting flags for $num.\n");
    my $failed = 0;
    my $resp = &send_command($HANDLE, "im$seq UID FETCH $num FLAGS", '');
    while ($resp !~ /^im$seq/) {
	if ($resp =~ /^\* NO/i) {
	    $failed = 1;
	} elsif ($resp =~ /^\* \d+ FETCH \(UID $num FLAGS \((.*)\)\)/i ||
		 $resp =~ /^\* \d+ FETCH \(FLAGS \((.*)\) UID $num\)/i) {
	    $flags = $1;
	}
	$resp = &next_response($HANDLE);
    }
    return '' if ($resp !~ /^im$seq OK/);
    return '' if ($failed);
    return $flags;
}

sub imap_delete ($$) {
    my ($HANDLE, $num) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("deleting message $num.\n");
    my $resp = &send_command($HANDLE,
	"im$seq UID STORE $num +FLAGS (\\Deleted)", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return 0;
}

sub imap_list_folder ($) {
    my ($HANDLE) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("listing folders.\n");
    my $resp = &send_command($HANDLE, "im$seq LIST \"\" *", '');
    my (@folders) = ();
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
        if ($resp =~ /^\* LIST \(([^)]*)\) (\S+) (\S+)/) {
            # \NoSelect should be skipped. but exclusive with \NoInferiors?
            push(@folders, $3)
              if (grep('\\NoInferiors' eq $_, split(' ', $1)));
        }
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return @folders;
}

sub imap_create_folder ($$) {
    my ($HANDLE, $folder) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("creating folder $folder.\n");
    my $resp = &send_command($HANDLE, "im$seq CREATE $folder", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return 0;
}

sub imap_delete_folder ($$) {
    my ($HANDLE, $folder) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("deleting folder $folder.\n");
    my $resp = &send_command($HANDLE, "im$seq DELETE $folder", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return 0;
}

sub imap_rename_folder ($$$) {
    my ($HANDLE, $old, $new) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("rename folder from $old to $new.\n");
    my $resp = &send_command($HANDLE, "im$seq RENAME $old $new", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return 0;
}

sub imap_copy ($$$$) {
    my ($HANDLE, $srcmsg, $dstfolder, $moveflag) = @_;
    im_notice("copying message $srcmsg to $dstfolder.\n");
#    my $resp = &imap_select($HANDLE, $dstfolder, 0);
#    if ($resp < 0) {
#        $resp = &imap_create_folder($HANDLE, $dstfolder);
#	if ($resp < 0) {
#	    im_err("can't create folder $dstfolder.\n");
#	    return -1;
#	}
#    }
    my $seq = $ImapSeq++;
    my $failed = 0;
    my $resp = &send_command($HANDLE,
			     "im$seq UID COPY $srcmsg $dstfolder", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    return -1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    if ($moveflag) {
	$resp = &imap_delete($HANDLE, $srcmsg);
    }
    return -1 if ($resp < 0);
    return 0;
}

sub imap_put ($$$) {
    my ($HANDLE, $folder, $Msg) = @_;
    my $seq = $ImapSeq++;
    my $failed = 0;
    im_notice("appending a new message to $folder.\n");
    my $size = 0;
    foreach (@$Msg) {
	s/\r?\n?$/\r\n/;
	$size += length($_);
    }
    my $resp = &send_command($HANDLE,
      "im$seq APPEND $folder (\\Seen) {$size}", '');
    if ($resp =~ /^\+/) {	# + Ready for argument
	foreach (@$Msg) {
	    send_data($HANDLE, $_, '');
	}
	send_data($HANDLE, '', '');
    }
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    $failed = 1 if ($resp !~ /^im$seq OK/);
    # synchronize
    $seq = $ImapSeq++;
    $resp = &send_command($HANDLE, "im$seq NOOP", '');
    while ($resp !~ /^im$seq/) {
	$failed = 1 if ($resp =~ /^\* NO/i);
	$resp = &next_response($HANDLE);
    }
    $failed = 1 if ($resp !~ /^im$seq OK/);
#   return -1 if ($failed);
    return 0;
}

# imap_process(handle, how, host, src, dst, limit)
sub imap_process ($$$$$$$) {
    my ($HANDLE, $how, $host, $src, $dst, $limit, $noscan) = @_;
    my ($msgs, $count) = (0, 0);
     if (($msgs = &imap_select($HANDLE, $src, 1)) < 0) {
         im_warn("selecting folder $src failed.\n"); 
         return -1;
     }
    $limit = $msgs if ($limit == 0);
    if ($how eq 'check') {
	if ($msgs > 0) {
	    im_msg("$msgs message(s) in $src at $host.\n");
	} else {
	    im_msg("no message in $src at $host.\n");
	}
    } elsif ($how eq 'from') {
	if ($msgs > 0) {
	    my @alluids = &imap_all_uids($HANDLE);
	    return -1 if ($alluids[0] < 0);
	    my $i;
	    foreach $i (@alluids) {
		return -1 if (&imap_from($HANDLE, $i) < 0);
	    }
	    im_info("$msgs message(s) in $src at $host.\n");
	} else {
	    im_info("no message in $src at $host.\n");
	}
    } elsif ($how eq 'get') {
	if ($msgs > 0) {
	    im_info("Getting new messages from $host into $dst....\n");
	    my @alluids = &imap_all_uids($HANDLE);
	    return -1 if ($alluids[0] < 0);
	    my $i;
	    foreach $i (@alluids) {
	        if ($count >= $limit) {
		    im_info("$count message(s).\n");
		    return $count;
		}  
		my ($rc, $message) = &imap_get($HANDLE, $i);
		return -1 if ($rc < 0);
		return -1 if (store_message($message, $dst, $noscan) < 0);
		&exec_getsbrfile($dst);
		unless ($main::opt_keep) {
 		    if (&imap_delete($HANDLE, $i) < 0) {
 		        im_warn("deleting message $i failed.");
 		        return -1;
 		    }  		  
		}
		$count++;
	    }
	    im_info("$msgs message(s).\n");
	} else {
	    im_info("no message in $src at $host.\n");
	}
    }
    return $msgs;
}

sub imap_get_msg ($$$$$) {
    my ($src, $dst, $how, $limit, $noscan) = @_;

    $src =~ s/^imap//i;

    my ($folder, $auth, $user, $host) = &imap_spec($src);
    return -1 if ($folder eq '');

    my ($pass, $agtfound, $interact) = getpass('imap', $auth, $host, $user);
    im_notice("accessing IMAP/$auth:$user\@$host for $how\n");
    my ($rc, $HANDLE) = &imap_open($auth, $host, $user, $pass);
    if ($rc == 0) {
	&savepass('imap', $auth, $host, $user, $pass)
	    if ($pass ne '' && $interact && &usepwagent());
	my $msgs = imap_process($HANDLE, $how, $host, $folder, $dst, $limit, $noscan);
	return -1 if ($msgs < 0);
	&imap_close($HANDLE);
	return $msgs;
    } else {
	my $prompt = lc("imap/$auth:$user\@$host");
	im_err("invalid password ($prompt).\n");	
	&savepass('imap', $auth, $host, $user, '')
	    if ($agtfound && &usepwagent());
	return -1;
    }
}

# IMAP folder (--src=imap[%folder][//auth][:user][@server[/port]])
sub imap_spec ($) {
    my $spec = shift;

    if ($spec eq '' || $spec !~ /[:\@]|\/\//) {
	my $s = imapaccount();
	if ($s !~ /^[\/\@:]/) {
	    if ($s =~ /\@/) {
		$s = ":$s";
	    } else {
		$s = "\@$s";
	    }
	}
	if ($spec ne '' && $s =~ /^\/[^\/]/) {
	    $s = "/$s";
	}
	$spec .= $s if ($s ne '');
    }

    my ($folder, $auth, $host) = ('INBOX', 'auth', 'localhost');
    my $user = $ENV{'USER'} || $ENV{'LOGNAME'} || im_getlogin();

    if ($spec =~ /^%(.*)\/(\/.*)/) {
	$folder = $1;
	$spec = $2;
    } elsif ($spec =~ /^%([^%:\@]+)(.*)/) {
	$folder = $1;
	$spec = $2;
    }	
    if ($spec =~ /^\/(\w+)(.*)/) {
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
	im_warn("invalid imap spec: $spec\n");
	return ('', '', '', '');
    }

    if ($auth =~ /^auth$/i) {
	$auth = 'AUTH';
    } elsif ($auth =~ /^login$/i) {
	$auth = 'LOGIN';
    } else {
	im_warn("unknown authentication protocol: $auth\n");
	return ('', '', '', '');
    }
    im_notice("folder=$folder auth=$auth user=$user host=$host\n");
    return ($folder, $auth, $user, $host);
}

sub imap_range2set ($@) {
    my ($HANDLE, @ranges) = @_;
    my (@uids, $fromuid, $dir);

    my @alluids = &imap_all_uids($HANDLE);
    return -1 if ($alluids[0] < 0);
    my ($min, $max) = ($alluids[0], $alluids[$#alluids]);

    @ranges = ('first-last') if ($#ranges < 0 || grep(/^all$/, @ranges));
    local $_;
    foreach (@ranges) {
	if (/^(\d+|first|last)-(\d+|first|last)$/) {
	    $fromuid = &imap_message_number($min, $max, $1);
	    if ($fromuid > $max) {
		$_ = '';
	    } else {
		$_ = "$fromuid:" . &imap_message_number($min, $max, $2);
	    }
	} elsif (/^(\d+|last|first):([+-]?)(\d+)$/) {
	    if ($1 eq 'last') {
		$dir = ($2 eq '+') ? +1 : -1;
	    } else {
		$dir = ($2 eq '-') ? -1 : +1;
	    }
	    $fromuid = &imap_message_number($min, $max, $1);
	    if ($dir > 0) {
		@uids = grep($_ >= $fromuid, @alluids);
		splice(@uids, $3) if ($3 < @uids);
	    } else {
		@uids = grep($_ <= $fromuid, @alluids);
		splice(@uids, 0, @uids - $3) if ($3 < @uids);
	    }
	    $_ = join(',', @uids);
	} elsif (/^(\d+|first|last)$/) {
	    $fromuid = &imap_message_number($min, $max, $1);
	    if ($fromuid > $max) {
		$_ = '';
	    } else {
		$_ = $fromuid;
	    }
	}
    }
    return join(',', grep($_, @ranges));
}

sub imap_range2msgs ($@) {
    my ($HANDLE, @ranges) = @_;
    my ($seq, $set, $resp, @uids);

    $set = &imap_range2set($HANDLE, @ranges);
    $seq = $ImapSeq++;
    $resp = &send_command($HANDLE, "im$seq UID SEARCH UID $set", '');
    if ($resp =~ /^\* SEARCH (\d[ \d]*)/i) {
	@uids = split(' ', $1);
    } else {
	im_warn("UID SEARCH command failed.\n");
	return (-1);
    }
    $resp = &next_response($HANDLE);
    return (-1) if ($resp !~ /^im$seq OK/);
    return wantarray ? @uids : $uids[0];
}

sub imap_folder_regname ($) {
    my $folder = shift;		# %...
    my ($auth, $user, $host);

    ($folder, $auth, $user, $host) = imap_spec($folder);
    $folder =~ s/^/%/;

    return "$folder//$auth:$user\@$host"; # may be appended '/port'
}

sub imap_folder_name ($) {
    my $folder = shift;

    if ($folder =~ /^%([^:\@]+)/) {
	$folder = $1;
	if ($folder =~ /(.*)\/\//) {
	    $folder = $1;
	}
	return $folder;		# folder without '%'
    }
    return '';
}

sub imap_folder_acct ($) {
    my $folder = shift;		# %...
    my ($auth, $user, $host);

    ($folder, $auth, $user, $host) = imap_spec($folder);

    if ($user && $host) {
	return "$user\@$host";
    }
    return '';
}

sub imap_all_uids ($) {
    my ($HANDLE) = @_;
    my ($seq, $resp, @uids);

    $seq = $ImapSeq++;
    $resp = &send_command($HANDLE, "im$seq UID SEARCH 1:*", '');
    if ($resp =~ /^\* SEARCH (\d[ \d]*)/i) {
	@uids = split(' ', $1);
    } else {
	im_warn("UID SEARCH command failed.\n");
	return (-1);
    }
    $resp = &next_response($HANDLE);
    return (-1) if ($resp !~ /^im$seq OK/);
    return @uids;
}

sub imap_message_number ($$$) {
    my ($min, $max, $num) = @_;

    return $num if $num =~ /^\d+$/;
    return $min if $num =~ /^first$/;
    return $max if $num =~ /^last$/;
    return '';
}

############################################
##
## For imls
##

sub imap_scan_folder ($$@) {
    my ($HANDLE, $folder, @ranges) = @_;
    my ($uid, $size, $len);

    my $msgset = &imap_range2set($HANDLE, @ranges);
    return  0 if !$msgset;
    return -1 if ($msgset < 0);
    my $count = 0;
    my $seq = $ImapSeq++;
    my $resp = &send_command($HANDLE,
	"im$seq UID FETCH $msgset (RFC822.SIZE RFC822.HEADER)", '');
    while ($resp =~
  /^\* \d+ FETCH \((UID (\d+) )?RFC822.SIZE (\d+) RFC822\.HEADER \{(\d+)\}/i) {
	($uid, $size, $len) = ($2, $3, $4);
	my @hdr;
	alarm(imap_timeout()) unless win95p();
	$! = 0;
	while (<$HANDLE>) {
	    unless (win95p()) {
		alarm(0);
		if ($!) {   # may be channel truoble
		    im_warn("lost connection for FETCH(scan).\n");
		    return -1;
		}
	    }
	    $len -= length;
	    s/\r?\n$/\n/;
	    im_warn($_) if (&debug('imap'));
	    push(@hdr, $_);
	    last if ($len <= 0);
	}
	alarm(0) unless win95p();
	$resp = &next_response($HANDLE);
	if (!$uid) {
	    return -1 if ($resp !~ /^ UID (\d+)\)/);
	    $uid = $1;
	} else {
	    return -1 if ($resp !~ /^\)/);
	}

	my %Head;
	&store_header(\%Head, join('', @hdr));
#	$Head{'bytes:'} = $size;
	$Head{'kbytes:'} = int(($size + 1023) / 1024);
	$Head{'number:'} = $uid;
	$Head{'folder:'} = "\%$folder";
	parse_header(\%Head);

#	if ($main::opt_thread) {
#	    &make_thread(%Head);
#	} else {
	    &disp_msg(\%Head);
	    $count++;
#	}
	$resp = &next_response($HANDLE);
    }
    if ($resp !~ /^im$seq OK/) {
	im_warn("UID FETCH command failed.\n");
	return -1;
    }
    return $count;
}

############################################
##
## For immv & imrm
##

my %ImapHandleCache = ();

sub imap_open_folders ($@) {
    my ($create, @folders) = @_;

    foreach (@folders) {
	next unless (/^%/);
	my $acct = imap_folder_acct($_);
	my $ifld = imap_folder_name($_);
	my ($rc, $HANDLE);

	unless ($HANDLE = $ImapHandleCache{$acct}) {
	    my ($dummy, $auth, $user, $host)
		= imap_spec(imap_folder_regname($_));

	    my ($pass, $agtfound, $interact) = 
		getpass('imap', $auth, $host, $user);

	    ($rc, $HANDLE) = imap_open($auth, $host, $user, $pass);
	    if ($rc < 0) {
		my $prompt = lc("imap/$auth:$user\@$host");
		im_err("invalid password ($prompt).\n");
		savepass('imap', $auth, $host, $user, '')
		    if ($agtfound && usepwagent());
		imap_close_folders();
		return -1;
	    }
	    savepass('imap', $auth, $host, $user, $pass)
		if ($interact && $pass ne '' && usepwagent());
	    $ImapHandleCache{$acct} = $HANDLE;
	}

	if ((imap_select($HANDLE, $ifld, 1) < 0) && $create) {
	    if (imap_create_folder($HANDLE, $ifld) < 0) {
		im_warn("can't create $_ folder.\n");
		imap_close_folders();
		return -1;
	    }
	}
    }
    return 0;
}

sub imap_close_folders () {
    foreach (keys(%ImapHandleCache)) {
	imap_close($ImapHandleCache{$_});
    }
    %ImapHandleCache = ();
}

sub imap_get_handle ($) {
    return $ImapHandleCache{imap_folder_acct(shift)};
}

sub imap_get_message ($$) {
    my ($src, $range) = @_;
    my $HANDLE = imap_get_handle($src);
    my $msg = imap_range2msgs($HANDLE, ($range));

    if ($msg < 0) {
	im_warn("can't find source message(s).\n");
	return ();
    }

    my ($rc, $msgref) = imap_get($HANDLE, $msg);
    if ($rc < 0) {
	im_warn("can't get msg $_ from source folder.\n");
	return ();
    }
    return $msgref;
}

sub imap_put_message ($$;$) {
    my ($Message, $dsts, $src_path) = @_;
    my $dst;

    foreach $dst (@$dsts) {
	my $HANDLE = imap_get_handle($dst);
	if (imap_put($HANDLE, imap_folder_name($dst), $Message) < 0) {
	    im_warn("can't store msg $src_path to $dst folder.\n");
	    return -1;
	}
    }
    return 0;
}

sub imap_put_file ($$$) {
    my ($src, $dsts, $src_path) = @_;
    my @Message;
    local (*SRC);

    unless (im_open(\*SRC, "<$src_path")) {
	im_warn("can't open local message $src_path.\n");
	return -1;
    }
    local $_;
    while (<SRC>) {
	push(@Message, $_);
    }
    close(SRC);

    return imap_put_message(\@Message, $dsts, $src_path);
}

sub imap_refile ($$$) {
    my ($src, $dsts, $msgs) = @_;
    my ($HANDLE, $srcacct, $srcset);
    my $link_1st;

    $srcacct = imap_folder_acct($src);
    $HANDLE = $ImapHandleCache{$srcacct};
    if (imap_select($HANDLE, imap_folder_name($src), 1) < 0) {
	im_warn("can't select $src source folder.\n");
	imap_close_folders();
	exit($EXIT_ERROR);
    }
    $srcset = imap_range2set($HANDLE, @$msgs);

    for (my $i = 0; $i < @$dsts; $i++) {
	if (imap_folder_acct($$dsts[$i]) eq $srcacct) {
	    my $dst = splice(@$dsts, $i, 1); $i--;
	    if (imap_copy($HANDLE, $srcset, imap_folder_name($dst), 0) < 0) {
		im_warn("can't copy to $dst folder.\n");
		return -1;
	    }
	}
    }
    unless (@$dsts) {
	imap_delete($HANDLE, $srcset) unless ($main::opt_link);
	imap_close_folders();
	return 0;
    }

    imap_delete($HANDLE, $srcset) unless ($main::opt_link);
    $msgs = ["$link_1st-last"];
    return 0;
}

sub imap_delete_message () {
    my ($src, @range) = @_;
    my $HANDLE = imap_get_handle($src);
    my $srcset = imap_range2set($HANDLE, @range);

    imap_delete($HANDLE, $srcset);
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
