# -*-Perl-*-
################################################################
###
###			     LocalMbox.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Mar 22, 2003
###

my $PM_VERSION = "IM::LocalMbox.pm version 20030322(IM144)";

package IM::LocalMbox;
require 5.003;
require Exporter;

use Fcntl;
use IM::Config;
use IM::Util;
use IM::MsgStore qw(store_message exec_getsbrfile fsync);
use integer;
use strict;
use vars qw(@ISA @EXPORT $getchk_hook);

@ISA = qw(Exporter);
@EXPORT = qw(local_get_msg);

use vars qw($locked_by_file $locked_by_flock);
#################################
# local mailbox access routines #
#################################

##### LOCAL SPOOL MANAGEMENT #####
#
# local_get_msg(src, dst, how)
#		check, from, get
#
sub local_get_msg($$$$$) {
    my($src, $dst, $how, $lock_type, $noscan) = @_;
    my($need_lock, $qmail_ok, $msgs, $l, $file, $p);
    my(@MailDrops);

    if ($how eq 'get') {
	$need_lock = 1;
    } else {
	$need_lock = 0;
    }

    (my $mbox = $src) =~ s/local:?//i;

    if (&mbox_style() =~ /qmail/i) {
	$qmail_ok = 1;
	im_notice("qmail access enabled.\n");
    } else {
	$qmail_ok = 0;
	im_notice("qmail access disabled.\n");
    }

#    my $user = $ENV{'USER'} || $ENV{'LOGNAME'} || im_getlogin();
    my $user = im_getlogin();
    my $home = $ENV{'HOME'};
    if ($user eq '' || $home eq '') {
	my @pw = getpwuid($<);
	$user = $pw[0] unless ($user);
	$home = $pw[7] unless ($home);
    }

    # set default
    unless ($mbox) {
	if ($qmail_ok) {
	    push(@MailDrops, $ENV{'MAILDIR'}) if ($ENV{'MAILDIR'});
	    push(@MailDrops, $ENV{'MAILDROP'}) if ($ENV{'MAILDROP'});
	    push(@MailDrops, $ENV{'MAIL'}) if ($ENV{'MAIL'});
	    push(@MailDrops, "$home/Maildir");
	    foreach $p (@MailDrops) {
		if ((-d $p && -d "$p/new" && -d "$p/cur") || -f $p) {
		    $mbox = $p;
		    last;
		}
	    }
	}
	unless ($mbox) {
	    @MailDrops = (
		"/var/mail/$user",
		"/var/spool/mail/$user",
		"/usr/mail/$user",
		"/usr/spool/mail/$user"
	    );
	    unshift(@MailDrops, "$home/Mailbox") if ($qmail_ok);
	    foreach $p (@MailDrops) {
		if (-f $p) {
		    $mbox = $p;
		    last;
		}
	    }
	}
	unless ($mbox) {
	    im_warn("mailbox for $user not found\n");
	    return -1;
	}
    }
    im_notice("mailbox for $user is $mbox\n");

    $getchk_hook = getchksbr_file();
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

    if (-d $mbox) {
	# DIRECTORY
	im_info("Getting new messages from maildir into $dst...\n")
	  if ($how eq 'get');

	my $msgs = 0;
	if ($qmail_ok && -d "$mbox/new" && -d "$mbox/cur") {
	    $msgs = process_maildir($mbox, $dst, $how, $noscan);
	} else {
	    unless (opendir(FLDR, $mbox)) {
		im_warn("can't open directory: $mbox\n");
		return -1;
	    }
	    my $f;
	    foreach $f (sort {$a <=> $b} readdir(FLDR)) {
		if ($f =~ /^\d+$/ && -s "$mbox/$f") {
		    if (process_file("$mbox/$f", $dst, $how, $noscan) < 0) {
			return -1;
		    }
		    if ($how eq 'get' && $main::opt_keep == 0) {
			$f =~ /(.+)/;	# $f is tainted yet
			$f = $1;	# clean up
			unlink("$mbox/$f");
		    }
		    $msgs++;
		}
	    }
	    closedir(FLDR);
	}
	if ($msgs == 0) {
	    if ($how eq 'check') {
		im_msg("no message in local maildir.\n");
	    } elsif ($how eq 'from') {
		im_info("no message in local maildir.\n");
	    } else {
		im_info("no messages in local maildir.\n");
	    }
	    return 0;
	}
	if ($how eq 'check') {
	    im_msg("$msgs message(s) in local maildir.\n");
	} elsif ($how eq 'from') {
	    im_info("$msgs message(s) in local maildir.\n");
	} elsif ($how eq 'get') {
	    flush('STDOUT');
	    im_info("$msgs message(s).\n");
	}
	return $msgs;
    } elsif (-s $mbox) {
	# FILE and not ZERO
	if ($need_lock) {
	    if (&local_lockmbox($mbox, $lock_type) < 0) {
		&local_unlockmbox($mbox);
		return -1;
	    }
	}
	if ($how eq 'get' && $getchk_hook ne '' && !$main::opt_keep) {
	    my $tmpmbox = expand_path('tmp_mbox');
	    if (local_copymbox($mbox, $tmpmbox) < 0) {
		return -1;
	    }

	    unless (im_open(\*SAVE, "+>$mbox")) {
		im_err("can't open $mbox ($!).\n");
		close(SAVE);
		return -1;
	    }

	    if (($msgs = process_mbox($tmpmbox, $dst, $how, $mbox, $noscan)) < 0) {
		close(SAVE);
		if (local_copymbox($tmpmbox, $mbox) < 0) {
		    im_err("write back to $mbox failed. $tmpmbox preserved ($!).\n");
		} else {
		    unlink($tmpmbox);
		}
		&local_unlockmbox($mbox) if ($need_lock);
		return -1;
	    }

	    if (&unixp() && !&no_sync()) {
		if (fsync(fileno(SAVE)) < 0) {
		    im_err("write back to $mbox failed ($!).\n");
		    close(SAVE);
		    unlink($tmpmbox) if (-z $tmpmbox);
		    return -1;
		}
	    }

	    truncate(SAVE, tell(SAVE));
	    unlink($tmpmbox);
	} else {
	    if (($msgs = process_mbox($mbox, $dst, $how, '', $noscan)) < 0) {
		&local_unlockmbox($mbox) if ($need_lock);
		return -1;
	    }
	    if ($how eq 'get') {
		&local_empty($mbox) unless ($main::opt_keep);
	    }
	}
	&local_unlockmbox($mbox) if ($need_lock);
	return $msgs;
    } else {
	if ($how eq 'check') {
	    im_msg("no message in local mailbox.\n");
	} elsif ($how eq 'from') {
	    im_info("no message in local mailbox.\n");
	} else {
	    im_info("no messages in local mailbox.\n");
	}
	return 0;
    }
}

sub local_copymbox($$) {
    my($src, $dst) = @_;

    im_debug("copy from $src to $dst\n") if (&debug('local'));
    unless (im_open(\*SRC, "<$src")) {
	return -1;
    }
    unless (im_open(\*DST, "+>$dst")) {
	return -1;
    }
    while (<SRC>) {
	unless (print DST) {
	    im_err("writing to $dst failed ($!).\n");
	    close(DST);
	    close(SRC);
	    unlink($dst) if (-z $dst);
	    return -1;
	}
    }
    if (&unixp() && !&no_sync()) {
	if (fsync(fileno(DST)) < 0) {
	    im_err("writing to $dst failed ($!).\n");
	    close(DST);
	    close(SRC);
	    unlink($dst) if (-z $dst);
	    return -1;
	}
    }
    truncate(DST, -s SRC);
    close(DST);
    close(SRC);
    return 0;
}

sub process_maildir($$$$) {
    my($maildir, $dst, $how, $noscan) = @_;
    my($msgs, $f, $dir);

    unless (-d "$maildir/new" && -r "$maildir/new" && -x "$maildir/new"
         && -d "$maildir/cur" && -r "$maildir/cur" && -x "$maildir/cur") {
	im_warn("can't open maildir: $dir\n");
	return -1;
    }

    $msgs = 0;
    foreach $dir ("$maildir/cur", "$maildir/new") {
	unless (opendir(FLDR, $dir)) {
	    im_warn("can't open directory: $dir\n");
	    return -1;
	}
	foreach $f (sort {(-M $b) <=> (-M $a) || $a cmp $b} readdir(FLDR)) {
	    if ($f =~ /^\d+\.(\d+|\d+_\d+)\..+/ && -s "$dir/$f") {
		my $ret = process_file("$dir/$f", $dst, $how, $noscan);
		next if ($ret > 0);	# skip by rule
		if ($ret < 0) {
		    closedir(FLDR);
		    return -1;
		}
		if ($how eq 'get' && $main::opt_keep == 0) {
		    $f =~ /(.+)/;	# $f is tainted yet
		    $f = $1;		# clean up
		    unlink("$dir/$f");
		}
		$msgs++;
	    }
	}
	closedir(FLDR);
    }
    return $msgs;
}

sub process_file($$$$) {
    my($mbox, $dst, $how, $noscan) = @_;
    my($format, $msgs, $rp, $length, $inheader, @Message);
    local(*MBOX);

    im_notice("opening MBOX ($mbox)\n");
    unless (im_open(\*MBOX, "<$mbox")) {
	# XXX not found or unreadable...
	return -1;
    }
    while (<MBOX>) {
	push (@Message, $_);
    }
    if ($getchk_hook ne '') {
	my %head;
	lcl_store_header(\%head, \@Message);
	unless (eval { &getchk_sub(\%head); }) {
	    close(MBOX);
	    return 1
	}
    }
    if ($how eq 'get') {
	if (store_message(\@Message, $dst, $noscan) < 0) {
	    close(MBOX);
	    return -1;
	}
    }
    close(MBOX);
    &exec_getsbrfile($dst);
    return 0;
}

sub process_mbox($$$$$) {
    my($mbox, $dst, $how, $save, $noscan) = @_;
    my($format, $msgs, $length, $inheader, @Message);
    local(*MBOX);
    my($first_line, $FIRST_LINE);

    im_info("Getting new messages from local mailbox into $dst...\n")
	if ($how eq 'get');
    im_warn("opening MBOX ($mbox)\n") if (&verbose);
    unless (im_open(\*MBOX, "<$mbox")) {
	# XXX not found or unreadable...
	return -1;
    }
    chomp($first_line = <MBOX>);
    if ($first_line =~ /^From /) {
	$format = 'UNIX';
	$FIRST_LINE = $first_line;
    } elsif ($first_line =~ /^\001\001\001\001$/) {
	$format = 'MMDF';
    } elsif ($first_line =~ /^BABYL OPTIONS:/) {
	$format = 'RMAIL';
    } else {
	im_warn("invalid mbox format: $mbox\n");
	return -1;
    }
    $msgs = 0;
    while ($first_line ne '') {
	im_notice("reading a message ($first_line)\n");

	if ($msgs > 0 && $format eq 'MMDF') {
	    $first_line = <MBOX>;
	    if ($first_line !~ /^\001\001\001\001$/) {
		last;
	    }
	}

	if ($format eq 'RMAIL') {
	    while (<MBOX>) {
		last if /^\*\*\* EOOH \*\*\*$/;
	    }
	}

	if ($how eq 'from' && $format eq 'UNIX') {
	    print "$first_line\n";
	}

	if ($format eq 'UNIX' && $main::opt_rpath ne 'ignore') {
	    # convert UNIX From_ into Return-Path
	    my $rp = $first_line;
	    $rp =~ s/^From +//;
	    $rp =~ s/ +[A-Z][a-z][a-z] [A-Z][a-z][a-z] [\d ]\d \d\d:\d\d.*//;
	    $rp = "<$rp>" if ($rp !~ /^<.*>$/);
	    @Message = ("Return-Path: $rp\n");
	} else {
	    @Message = ();
	}

	$first_line = '';
	$inheader = 1;
	$length = -1;
	while (<MBOX>) {
	    if ($format eq 'MMDF' && $_ =~ /^\001\001\001\001$/) {
		$first_line = 'MMDF';
		last;
	    } elsif ($format eq 'UNIX' && $length <= 0
		  && /^From / && $Message[$#Message] eq "\n") {
		chomp($first_line = $_);
		last;
	    } elsif ($format eq 'RMAIL' && /^\x1f/) {
		chomp($first_line = <MBOX>);
		last;
	    } elsif ($inheader) {
		if ($format eq 'MMDF' && $how eq 'from') {
		    print "$_" if (/^From:/i);
		}
		# XXX continuous line processing needed
		push(@Message, $_)
		    unless (/^Return-Path:/i && $main::opt_rpath eq 'replace');
		# for Solaris 2.x or ...
		# XXX option
		if ($main::Obey_CL && /^Content-Length:(.*)/i) {
		    chomp($length = $1);
		}
		$inheader = 0 if (/^\n$/);
	    } else {
		push(@Message, $_);
		$length -= length($_) if ($length > 0);
	    }
	}

	if ($Message[$#Message] eq "\n") {
	    pop(@Message);
	}

	if ($getchk_hook) {
	    my %head;
	    lcl_store_header(\%head, \@Message);
	    unless (eval { &getchk_sub(\%head); }) {
		if (save_message(\@Message, $save, $format, $FIRST_LINE) < 0) {
		    close(MBOX);
		    return -1;
		}
		next;
	    }
	}
	$msgs++ if ($#Message >= 0);

	if ($how eq 'get') {
	    if (store_message(\@Message, $dst, $noscan) < 0) {
		close(MBOX);
		return -1;
	    }
	}
    }
    close(MBOX);
    if ($how eq 'check') {
	im_msg("$msgs message(s) in local mailbox.\n");
    } elsif ($how eq 'from') {
	im_info("$msgs message(s) in local mailbox.\n");
    } elsif ($how eq 'get') {
	flush('STDOUT');
	im_info("$msgs message(s).\n");
	&exec_getsbrfile($dst);
    }
    return $msgs;
}

sub save_message($$$$) {
    my($msg, $save, $mode, $fline) = @_;

    im_debug("saving to $save\n") if (&debug('local'));
    if ($mode eq 'UNIX') {
	shift(@$msg);
	unless (print SAVE "$fline\n") {
	    im_err("writing to $save failed ($!).\n");
	    close(SAVE);
	    return -1;
	}
    } elsif ($mode eq 'RMAIL') {
	if (tell(SAVE) == 0) {
	    unless (print SAVE "BABYL OPTIONS:\n") {
		im_err("writing to $save failed ($!).\n");
		close(SAVE);
		return -1;
	    }
	}
    } elsif ($mode eq 'MMDF') {
	if (tell(SAVE) == 0) {
	    unless (print SAVE "\001\001\001\001\n") {
		im_err("writing to $save failed ($!).\n");
		close(SAVE);
		return -1;
	    }
	}
    }
    foreach (@$msg) {
	unless (print SAVE) {
	    im_err("writing to $save failed ($!).\n");
	    close(SAVE);
	    return -1;
	}
    }
    if ($mode eq 'UNIX') {
	unless (print SAVE "\n") {
	    im_err("writing to $save failed ($!).\n");
	    close(SAVE);
	    return -1;
	}
    } elsif ($mode eq 'RMAIL') {
	unless (print SAVE "*** EOOH ***\n") {
	    im_err("writing to $save failed ($!).\n");
	    close(SAVE);
	    return -1;
	}
    } elsif ($mode eq 'MMDF') {
    }
    return 0;
}

sub local_empty($) {
    my $mbox = shift;
    unless (truncate($mbox, 0)) {
	unless (im_open(\*MBOX, ">$mbox")) {
	    im_warn("mailbox can not be zeroed.\n");
	    return;
	}
	close(MBOX);
    }
    im_notice("local mailbox has been zeroed.\n");
}

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

sub local_lockmbox($$) {
    my($base, $type) = @_;
    my $retry = 0;
    im_warn("creating lock file with uid=$> gid=$)\n") if (&debug('local'));

    $locked_by_file = 0;
    $locked_by_flock = 0;
    if ($type =~ /file/) {
#	while (!sysopen(LOCK, "$base.lock", O_RDWR()|O_CREAT()|O_EXCL())) {
#	    if ($retry >= 10) {
#		im_warn("can't create $base.lock: $!\n");
#		return -1;
#	    }
#	    im_warn("mailbox is processed by another process, waiting...\n")
#	      if ($retry == 0);
#	    $retry++;
#	    sleep(5);
#	}

	unless (im_open(\*LOCKFILE, ">$base.$$")) {
	    im_warn("can't create lock file $base.$$: $!\n");
	    im_warn("use 'flock' instead of 'file' if possible.\n");
	    return -1;
	}
	print LOCKFILE "$$\n";
	close(LOCKFILE);
	while (!link("$base.$$", "$base.lock")) {
	    if ($retry >= 10) {
		im_warn("can't create $base.lock: $!\n");
		unlink("$base.$$");
		return -1;
	    }
	    im_warn("mailbox is owned by another process, waiting...\n")
	      if ($retry == 0);
	    $retry++;
	    sleep(5);
	}
	unlink("$base.$$");
	$locked_by_file = 1;
    }
    if ($type =~ /flock/) {
	unless (im_open(\*LOCK_FH, "+<$base")) {
	    im_err "can't open $base :$!\n";
	    return -1;
	}
	if (! &win95p) {
	unless (flock (LOCK_FH, LOCK_EX|LOCK_NB)) {
	    im_warn "can't flock $base: $!\n";
	    return -1;
	}
	}
	$locked_by_flock = 1;
    }
    return 0;
}

sub local_unlockmbox($) {
    my $base = shift;
    my $rcode = 0;
    im_debug("removing lock file with uid=$> gid=$)\n") if (&debug('local'));
    if ($locked_by_file) {
	if (-f "$base.lock" && unlink("$base.lock") <= 0) {
	    im_warn("can't unlink lock file $base.lock: $!\n");
	    $rcode = -1;
	}
	$locked_by_file = 0;
    }
    if ($locked_by_flock) {
        if (! &win95p) {
	flock(LOCK_FH, LOCK_UN);
        }
	$locked_by_flock = 0;
    }
    return $rcode;
}

sub lcl_store_header($$) {
    my($href, $msg) = @_;
    my($line);

    foreach (@$msg) {
	my $l = $_;
	chomp($l);
	last if ($l =~ /^$/);
	if ($l =~ /^\s/) {
	    $l =~ s/\s+/ /;
	    $line .= $l;
	    next;
	} else {
	    lcl_set_line($href, $line);
	    $line = $l;
	}
    }
    lcl_set_line($href, $line);
}

sub lcl_set_line($$) {
    my($href, $line) = @_;

    return unless ($line =~ /^([^:]*):\s*(.*)$/);
    my $label = lc($1);
    return if ($label eq 'received');
    if (defined($href->{$label})) {
#	if ($STRUCTURED_HASH{$label}) {
#	    $href->{$label} .= ", ";
#	} else {
	    $href->{$label} .= "\n\t";
#	}
	$href->{$label} .= $2;
    } else {
	$href->{$label} = $2;
    }
}

1;

__END__

=head1 NAME

IM::LocalMbox - local mailbox managing

=head1 SYNOPSIS

 use IM::LocalMbox;

 $num_msgs = &local_get_msg(source_mailbox, destination_folder, access_mode);

=head1 DESCRIPTION

The I<IM::LocalMbox> module handles local mailbox.
MH folder, MMDF file, mbox, and Maildir are supported.

This modules is provided by IM (Internet Message).

=head1 EXAMPLES

 $mbox = 'local:/var/mail/motonori';
 $folder = '+inbox'
 $num_msgs = &local_get_msg($mbox, $folder, 'get');

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
