# -*-Perl-*-
################################################################
###
###			     MsgStore.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Oct 28, 2003
###

my $PM_VERSION = "IM::MsgStore.pm version 20031028(IM146)";

package IM::MsgStore;
require 5.003;
require Exporter;

use Fcntl;
use IM::Config qw(getsbr_file msg_mode msgdbfile expand_path
		  inbox_folder no_sync fsync_no preferred_fsync_no file_attr);
use IM::Util;
use IM::Folder qw(message_number message_name create_folder touch_folder);
use IM::Message qw(gen_date);
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(store_message exec_getsbrfile open_fcc excl_create fsync);

use vars qw($MsgNum $PrevFolder $First $Last $PrevDst $sys_fsync);
BEGIN {
    $MsgNum = 0;
    $PrevFolder = '';
    $First = 0;
    $Last = 0;
    $PrevDst = '';
}

##### OPEN A FILE TO SAME NEW MESSAGE IN MAIL FOLDER #####
#
# new_message(handle, folder_name)
#	folder_name: a folder name to be saved in
#	return value:
#		success: file name to be saved
#		fail: NULL
#
sub new_message(\*$) {
    (local *MESSAGE, my $folder) = @_;
    if ($folder ne $PrevFolder) {
        $MsgNum = 0;
        $PrevFolder = $folder;
    }
    if ($MsgNum == 0) {
	$MsgNum = message_number($folder, 'new');
	if ($MsgNum == 0) {
	    im_warn("can't get new message number in $folder\n");
	    return ('', '');
	}
	$First = $Last = $MsgNum;
    } else {
	$MsgNum = message_number($folder, 'new', ($MsgNum));
	if ($MsgNum == 0) {
	    im_warn("can't get new message number in $folder\n");
	    return ('', '');
	}
    }
    my $try = 3;
    while ($try--) {
	my $file = message_name($folder, $MsgNum);
	im_notice("creating file: $file\n");
	unless ($file) {
	    # message path allocation failed
	    return ('', '');
	}
	if (excl_create(\*MESSAGE, $file) == 0) {
	    # created successfully
	    $Last = $MsgNum;
	    return ("$folder/$MsgNum", $file);
	}
	$MsgNum = message_number($folder, 'new', ($MsgNum));
	if ($MsgNum == 0) {
	    im_warn("can't get new message number in $folder\n");
	    return ('', '');
	}
    }
    im_warn("excl_create failed.\n");
    # message creation failed
    return ('', '');
}

sub store_message($$;$) {
    my($Msg, $dst, $noscan) = @_;
    local *ART;
    require IM::Scan && import IM::Scan qw(store_header parse_header
					   parse_body disp_msg);

    im_notice("saving the message into $dst\n");
    if ($PrevDst ne $dst) {
	if (create_folder($dst) < 0) {
	    return -1;
	}
	touch_folder($dst);
	$PrevDst = $dst;
    }
    my($msgfile, $filepath) = &new_message(\*ART, $dst);
    my $size = 0;
    if ($filepath ne '') {
	my $line;
	my $hcount = 0;
	my $inheader = 1;
	if (&unixp() && !&no_sync()) {
	    select (ART); $| = 1; select (STDOUT);
	}
	im_notice("creating $filepath\n");
	foreach $line (@$Msg) {
	    $size += length($line);
	    if ($line eq "\n") {
		$inheader = 0;
	    }
	    $hcount++ if ($inheader);
	    unless (print ART $line) {
		im_err("writing to $filepath failed ($!).\n");
		close(ART);
		unlink($filepath) if (-z $filepath);
		return -1;
	    }
	}
	if (&unixp() && !&no_sync()) {
	    if (fsync(fileno(ART)) < 0) {
		im_err("writing to $filepath failed ($!).\n");
		close(ART);
		unlink($filepath) if (-z $filepath);
		return -1;
	    }
	}
	unless (close(ART)) {
	    im_err("writing to $filepath failed ($!).\n");
	    unlink($filepath) if (-z $filepath);
	    return -1;
	}

	my @Hdr = @$Msg[0..$hcount];
	my %Head;
	store_header(\%Head, join('', @Hdr));

	unless ($noscan) {
	    splice(@$Msg, 0, $hcount);
	    $Head{'body:'} = &parse_body($Msg, 1);

#	    $Head{'bytes:'} = $size;
	    $Head{'kbytes:'} = int(($size + 1023) / 1024);
	    ($Head{'number:'} = $msgfile) =~ s/^.*\///;
	    $Head{'folder:'} = $dst;
	    &parse_header(\%Head);
#	    if ($main::opt_thread) {
#		&make_thread(%Head);
#	    } else {
		&disp_msg(\%Head);
		$main::scan_count++;
#	    }
	}

	my $mid = $Head{'message-id'};
#	my $dt = $Head{'date'};
	(my $ver = $Head{'mime-version'}) =~ s/\s//g;
	my $master = '';
	if ($ver eq '1.0') {
	    my $ct = $Head{'content-type'} . ';';
	    $ct =~ s/\s//g;
	    if ($ct =~ m|^Message/partial;(.*;)?id=([^;]+);|i) {
		$master = $2;
		$master =~ s/^"(.*)"$/$1/;
	    }
	}
	if (&msgdbfile() ne '' && $mid ne '') {
	    require IM::History && import IM::History;

	    unless (history_open(1) < 0) {
		history_store($mid, $msgfile);
		history_store("partial:$master", $mid) if ($master ne '');
		history_close();
	    }
	}
	return 0;
    } else {
	im_err("message can not be saved to $dst.\n");
	return -1;
    }
}

sub exec_getsbrfile($) {
    my $dst = shift;
    my $get_hook = getsbr_file();
    if ($get_hook) {
	if ($main::INSECURE) {
	    im_warn("Sorry, GetSbr is ignored for SUID root script\n");
	    return;
	}
	if ($get_hook =~ /(.+)/) {
	    if ($> != 0) {
		$get_hook = $1;        # to pass through taint check
	    }
	    if (-f $get_hook) {
		require $get_hook;
	    } else {
		im_err("get subroutine file $get_hook not found.\n");
	    }
	}
	eval { &get_sub($dst, $First, $Last); };
	if ($@) {
	    im_warn("Form seems to be wrong.\nPerl error message is: $@");
	}
    }
    return;
}

##### OPEN FILE FOR FCC #####
#
# open_fcc(folder_name, save_style)
#	folder_name: a folder name to be saved in
#	save_style:
#		0 = messages in a file
#		1 = separated messages in a directory
#	return values: (handle, fcc_dir, path, rm_file_on_error)
#	  handle:
#		NULL  : failed
#		Handle: success
#	  fcc_dir: directory name
#	  path: file name to be saved
#	  rm_file_on_error: a path to be deleted on error
#
sub open_fcc($$) {
    my($folder, $dir_style) = @_;
    my($fcc_dir, $rm_file_on_error, $fcc_folder, $FILE, $msgfile);
    $fcc_folder = &expand_path($folder);

    if (-d $fcc_folder) {
	$fcc_dir = 1;
    } elsif (-f $fcc_folder) {
	$fcc_dir = 0;
    } else {
	# set default style unless exists
	$fcc_dir = $dir_style;
    }
    im_debug("FCC style: ".($fcc_dir?"Dir":"File")."\n") if (&debug('fcc'));

    unless ($fcc_dir) {
	msg_mode(1);
	im_debug("FCC file: $fcc_folder\n") if (&debug('fcc'));
	unless (im_open(\*FCC, ">>$fcc_folder")) {
	    im_warn("can't open FCC file: $fcc_folder\n");
	    return undef;
	}

	my $date = &gen_date(2);
	unless (print(FCC "From $main::Sender $date\n")) {
	    close(FCC);
	    im_warn("can't write FCC file: $fcc_folder\n");
	    return undef;
	}
	$msgfile = $folder;
	$rm_file_on_error = '';
    } else {
	unless (-d $fcc_folder) {
	    if (create_folder($fcc_folder) < 0) {
		im_warn("can't create folder: $fcc_folder\n");
		return undef;
	    }
	}
	($msgfile, $rm_file_on_error) = &new_message(\*FCC, $folder);
	return undef if ($msgfile eq '');
	touch_folder($msgfile);
	im_debug("FCC storing in $rm_file_on_error\n")
	  if (&debug('fcc'));
    }
    if (&unixp() && !&no_sync()) {
	select (FCC); $| = 1; select (STDOUT);
    }
    return (\*FCC, $fcc_dir, $msgfile, $rm_file_on_error);
}

# excl_create(handle, file)
#	file: path of file to be created exclusively
#	handle: file handle
#	return value:
#	  0: success
#	 -1: fail
#
sub excl_create(*$) {
    (local *MESSAGE, my $file) = @_;
    msg_mode(1);
    return -1 unless (im_sysopen(\*MESSAGE, $file, file_attr()));
    return 0;
}

sub fsync($) {
    my $fno = shift;

    if (preferred_fsync_no()) {
	return syscall(preferred_fsync_no(), $fno);
    }
    # try to find from header files
    unless (defined($sys_fsync)) {
	eval { require 'syscall.ph'; };
	unless ($@) {
	    $sys_fsync = &SYS_fsync if (defined(&SYS_fsync));
	}
	unless ($sys_fsync) {
	    if (-f '/usr/include/sys.s') {  # for IRIX...
		# create sys.ph from sys.s
		eval { require 'sys.ph'; };
		unless ($@) {
		    $sys_fsync = &SYS_fsync if (defined(&SYS_fsync));
		}
	    }
	}
	unless ($sys_fsync) {
#	    im_warn ("syscall.ph not found. using syscall.h instead.\n");
	    if (open(SYSCALL_H, '</usr/include/sys/syscall.h')) {
		while (<SYSCALL_H>) {
		    if (/^\s*#\s*define\s+SYS_fsync\s+(\d+)/) {
			$sys_fsync = $1;
			last;
		    }
		}
		close(SYSCALL_H);
	    }
	}
	unless ($sys_fsync) {
	    # try to use SYS_fsync number detected when configure
	    $sys_fsync = fsync_no();
	}
	unless ($sys_fsync) {
	    im_die("Can't find a way to fsync(). Set NoSync=yes in your Config file and be careful on file system overflow if your mail folders are on NFS.\n");
	}
    }
    return syscall($sys_fsync, $fno);
}

1;

__END__

=head1 NAME

IM::MsgStore - store message in MH-style folder

=head1 SYNOPSIS

 use IM::MsgStore;

Subroutines:
store_message exec_getsbrfile open_fcc excl_create fsync

=head1 DESCRIPTION

The I<IM::MsgStore> module stores mail/news messages in MH-style folder.

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
