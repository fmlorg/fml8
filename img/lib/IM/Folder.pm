# -*-Perl-*-
################################################################
###
###			      Folder.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Jun  1, 2003
###

my $PM_VERSION = "IM::Folder.pm version 20030601(IM145)";

package IM::Folder;
require 5.003;
require Exporter;

use IM::Config qw(expand_path context_file inbox_folder folder_mode usetouchfile touchfile);
use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(cur_folder set_cur_folder folder_info
	message_list message_number message_range message_name
	get_message_paths create_folder touch_folder
        chk_folder_existance chk_msg_existance get_impath);

#
# Mail folder related routines.
#

sub cur_folder() {
    my $folder;
    local(*IN);

    return inbox_folder() if (! -f context_file());

    $folder = '';
    im_open(\*IN, '< ' . context_file()) || im_die("can't open context file.\n");
    while (<IN>) {
	chomp;
	if (/^CurrentFolder[:=]\s*(\S+)$/) {
	    $folder = $1;
	}
    }
    close(IN);
    return $folder;
}

sub set_cur_folder($) {
    my($folder) = @_;
    local(*IN, *OUT);
    my($buf);

    $buf = '';

    if (-f context_file()) {
	im_open(\*IN, '<' . context_file()) || im_die("can't open context file.\n");
	while (<IN>) {
	    chomp;
	    next if (/^CurrentFolder[:=]\s*(\S+)$/);
	    $buf .= $_ . "\n";
	}
	close(IN);
    }

    im_open(\*OUT, '>' . context_file()) || im_die("can't open context file.\n");
    print OUT $buf;
    print OUT "CurrentFolder=$folder\n";
    close(OUT);
}

sub folder_info($) {
    my($folder) = @_;
    local(*DIR);
    my(@allfiles, $filecnt, $numfilecnt, $min, $max);

    opendir(DIR, &expand_path($folder)) || im_die("can't open $folder.\n");
    @allfiles = grep(!/^\./, readdir(DIR));
    $filecnt = scalar(@allfiles);
    @allfiles = grep(/^\d+$/, @allfiles);
    $numfilecnt = scalar(@allfiles);
    $min = (sort {$a <=> $b} @allfiles)[0];
    $max = (sort {$b <=> $a} @allfiles)[0];
    closedir(DIR);

    return ($filecnt, $numfilecnt, $min, $max);
}

sub message_list($) {
    my($folder_dir) = @_;
    my @filesinfolder;

    opendir(DIR, $folder_dir) || im_die("can't open $folder_dir.\n");
    @filesinfolder = sort {$a <=> $b} grep(/^\d+$/, readdir(DIR));
    closedir(DIR);

    return @filesinfolder;
}

sub message_number($$;@) {
    my($folder, $number, @filesinfolder) = @_;
    my($folder_dir, $offset, $max, $min);

    # simple case: digits
    if ($number !~ /\D/) {
	return $number;
    }

    # get folder
    $folder = cur_folder if ($folder eq '');
    $folder_dir = expand_path($folder);
    return '' if (! -d $folder_dir);

    @filesinfolder = message_list($folder_dir) if (scalar(@_) == 2);

    if (scalar(@filesinfolder) == 0) {
	if ($number eq 'new') {
	    $number = '1';
	    while (-e "$folder_dir/$number" || -e "$folder_dir/.$number.dir") {
		$number++;
	    }
	    return $number;
	} else {
	    return '';
	}
    }

    $min = $filesinfolder[0];
    $max = $filesinfolder[$#filesinfolder];

    # items that need reverse ordered list
    if ($number eq 'last') {
	return $max;
    }
    if ($number eq 'first') {
	return $min;
    }
    if ($number eq 'new') {
	$number = $max + 1;
	while (-e "$folder_dir/$number" || -e "$folder_dir/.$number.dir") {
	    $number++;
	}
	return $number;
    }
    if ($number eq 'next' || $number eq 'prev') {
	$offset = ($number eq 'prev') ?  -1 : +1;

	$number += $offset;
	while ($min <= $number && $number <= $max) {
	    return $number if (-f "$folder_dir/$number");
	    $number += $offset;
	}
    }
    return '';
}

sub message_range($$@) {
    my($folder, $range, @filesinfolder) = @_;
    my $range_regexp = '\d+|first|last|next|prev';

    $folder = cur_folder if ($folder eq '');
    my $folder_dir = expand_path($folder);

    if ($range eq 'all') {
	$range = 'first-last';
    }

    if ($range =~ /^($range_regexp|new)-($range_regexp|new)$/) {
	my($start, $end) = ($1, $2);

	$start = message_number($folder, $start, @filesinfolder);
	$end = message_number($folder, $end, @filesinfolder);

	if ($start eq '' || $end eq '' || $start > $end) {
	    return ();
	} else {
	    return grep($start <= $_ && $_ <= $end, @filesinfolder);
	}
    } elsif ($range =~ /^($range_regexp):([+-]?)(\d+)$/) {
	my($start, $dir, $n) = ($1, $2, $3);
	if ($dir eq '') {
	    $dir = ($start eq 'last') ? '-' : '+';
	}
	$start = message_number($folder, $start, @filesinfolder);
	return $range if ($start eq '');

	if ($dir eq '+') {
	    @filesinfolder = grep($start <= $_, @filesinfolder);
	    splice(@filesinfolder, $n) if $n < scalar(@filesinfolder);
	} else {
	    @filesinfolder = grep($_ <= $start, @filesinfolder);
	    splice(@filesinfolder, 0, @filesinfolder - $n)
		if $n < scalar(@filesinfolder);
	}
	return @filesinfolder;
    } else {
	return message_number($folder, $range);
    }
}

sub message_name($$) {
    my($folder, $number) = @_;

    $number = &message_number($folder, $number);
    if ($number eq '') {
	return '';
    } else {
	return &expand_path($folder) . '/' . $number;
    }
}

sub get_message_paths($@) {
    my($folder, @messages0) = @_; # local @messages0?
    my($i, @messages, @x); # local(@messages, @x);?

    my $folder_dir = &expand_path($folder);

    # no message specified:
    # just print the path to the folder, and quit.
    if (scalar(@messages0) == 0) {
	return ($folder_dir);
    }

    # messages specified.
    # print the path to the message.
    if (! -d $folder_dir) {
	$@ = "no such folder $folder";
	return ();
    }

    # ad hoc but fast
    if (scalar(@messages0) == 1 && $messages0[0] eq 'new') {
	local(*MDIR);
	my($i);
	my $max = "0";
	opendir(MDIR, $folder_dir) || im_die("can't open $folder.\n");
	while (defined($i = readdir(MDIR))) {
	    $max = $i if ($max < $i and $i =~ /^\d+$/);
	}
	$max++;
	closedir(MDIR);
	return "$folder_dir/$max";
    }

    my @filesinfolder = message_list($folder_dir);

    @messages = @x = ();
    foreach $i (@messages0) {
	if ((@x = &message_range($folder, $i, @filesinfolder)) eq '') {
	    $@ = "message $i out of range";
	    return ();
	}
	push(@messages, @x);
    }

    grep($_ = "$folder_dir/$_", @messages);
}

sub create_folder($) {
    my $folder = shift;
    my $path = &expand_path($folder);
    return 0 if (-d $path);
    my $p = '';
    my $subdir;
    foreach $subdir (split('/', $path)) {
	if ($p eq '' && $subdir =~ /^\w:$/) {
	    $p = $subdir;
	    next;
	}
	$p .= "/$subdir";
	if ($> != 0) {
	    $p =~ /(.+)/;	# may be tainted
	    $p = $1;	# clean up
	}
	unless (-d $p) {
#	    im_debug("Creating directory: $p\n")
#	      if (&debug('folder'));
	    unless (mkdir($p, &folder_mode(0))) {
		im_err("can't create directory $p ($!)\n");
		return -1;
	    }
	}
    }
    return 0;
}

sub touch_folder($) {
    if (&usetouchfile()) {
 	my($dir) = shift;
 	$dir =~ s/\/\d+$//;
 	$dir = &expand_path($dir);
 	my($file) = ($dir . "/" . &touchfile());
	im_open(\*OF,">$file");
	print OF "touched by IM.";
	close(OF);
    } elsif (&os2p) {
	my($dir) = shift;
	$dir =~ s/\/\d+$//;
	$dir = &expand_path($dir);
	my $now = time;	# XXX
	utime ($now, $now, $dir);
    }
}

##
## Check folder existance.
##
sub chk_folder_existance(@) {
    my @folders = @_;
    my $path;

    im_debug("chk_folder_existance: folder: @folders\n") if (&debug('all'));

    foreach (@folders) {
	next if /^[%-]/;		# skip IMAP and News folders
	$path = get_impath($_);

	if (-e $path) {
	    im_die "folder $_ is not writable. (Nothing was refiled.)\n"
		if (! -w $path);
	} else {
	    if (create_folder($path) == 0) {
		im_warn "created folder $_.\n";
	    } else {
		im_die "cannot create folder $_. (Nothing was refiled.)\n";
	    }
	}
    }
    im_debug("chk_folder_existance: OK.\n") if (&debug('all'));
}

sub chk_msg_existance($@) {
    my $folder = shift;
    my @paths  = get_impath($folder, @_);

    im_debug("chk_msg_existance: folder: $folder msg: @_\n") if (&debug('all'));

    foreach (@paths) {
	if (! -f $_) {
	    im_die "message specification error in $folder. (Nothing was refiled.)\n";
	}
    }
    im_debug("chk_msg_existance: OK.\n") if (&debug('all'));;
}

sub get_impath($@) {
    my $folder = shift;
    my @msgs  = @_;
    my @paths;

    im_debug("impath: folder: $folder msgs: @msgs\n") if (&debug('all'));;
    @paths = get_message_paths($folder, @msgs);
    im_debug("impath: paths: @paths\n") if (&debug('all'));;

    return wantarray ? @paths : $paths[0];
}

1;

__END__

=head1 NAME

IM::Folder - mail/news folder handler

=head1 SYNOPSIS

 use IM::Folder;

 $current_folder_name = &cur_folder();

 &set_cur_folder($new_current_folder_name);

 ($number_of_files,
  $number_of_message_files,
  $minimum_message_number,
  $maximum_message_number) = &folder_info($folder_name);

 $message_number = &message_number($message_number_or_name);

 @message_number_array = &message_range($message_range_string);

 $message_file_path = &message_name($folder_name, $message_number);

=head1 DESCRIPTION

The I<IM::Folder> module handles mail/news message folders.

This modules is provided by IM (Internet Message).

=head1 EXAMPLES

 &cur_folder();
     results "+inbox"

 &set_cur_folder("+inbox");

 ($a, $b, $c, $d) = &folder_info("+inbox");
     results (10, 3, 1, 3)

 &message_number("+inbox", "cur");
     results 3

 &message_range("+inbox", "1-3");
     results (1, 2, 3)

 &message_name("+inbox", "3");
     results "/usr/home/itojun/Mail/inbox/3"

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
