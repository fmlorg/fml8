# -*-Perl-*-
################################################################
###
###			      History.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Jul 6, 1997
### Revised: Mar 22, 2003
###

my $PM_VERSION = "IM::History.pm version 20030322(IM144)";

package IM::History;
require 5.003;
require Exporter;

use Fcntl;
use IM::Config qw(msg_mode msgdbfile msgdbtype db_type);
use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(
	LookUpAll LookUpMsg
	history_open history_close
	history_store history_lookup history_delete history_dump
	history_rename history_link
);

use vars qw($DBtype $locked $nodbfile $DB_HASH %History);

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }


sub LookUpAll  { -1 }
sub LookUpMsg  {  0 }
#sub LookUpDate {  1 }


sub history_open($) {
    my($with_lock) = @_;
    $DBtype = msgdbtype();	# package global
    unless ($DBtype) {
	$DBtype = db_type();
    }

    $locked = 0;

    my $dbfile = msgdbfile();
    if ($dbfile eq '') {
	$nodbfile = 1;
	return -2;
    }

    if ($DBtype eq 'DB') {
	require DB_File && import DB_File;
	$DB_HASH->{'cachesize'} = 100000 ;
    } elsif ($DBtype eq 'NDBM') {
	require NDBM_File && import NDBM_File;
    } elsif ($DBtype eq 'SDBM') {
	require SDBM_File && import SDBM_File;
    } elsif ($DBtype eq '') {
	im_err("no DB type defined.\n");
	return -2;
    } else {
	im_err("DB type $DBtype is not supported.\n");
	return -2;
    }

    im_debug("history database: $dbfile\n") if (&debug('history'));

    my($db, $fd);
    if ($DBtype eq 'DB') {
	$db = tie %History, 'DB_File', $dbfile, O_CREAT()|O_RDWR(), &msg_mode(0);
    } elsif ($DBtype eq 'NDBM') {
	$db = tie %History, 'NDBM_File', $dbfile, O_CREAT()|O_RDWR(), &msg_mode(0);
    } elsif ($DBtype eq 'SDBM') {
	if (&win95p || &os2p) {
	    $db = tie %History, 'SDBM_File', $dbfile, O_CREAT()|O_RDWR()|O_BINARY(), &msg_mode(0);
	} else {
	    $db = tie %History, 'SDBM_File', $dbfile, O_CREAT()|O_RDWR(), &msg_mode(0);
	}
    }

    unless ($db) {
	im_err "history: can not access $dbfile ($!)\n";
	return -1;
    }
    if ($DBtype eq 'DB') {
	$fd = $db->fd;
	if ($fd < 0) {
	    im_err "history: can not access $dbfile (fd = $fd)\n";
	    return -1;
	}
    }

    return 0 unless ($with_lock);

    if ($DBtype eq 'DB') {
	unless (im_open(\*HIST_FH, "+<&=$fd")) {
	    im_err "history: dup $fd ($!)\n";
	    return -1;
	}
    } elsif ($DBtype eq 'NDBM' or $DBtype eq 'SDBM') {
	unless (im_open(\*HIST_FH, "+<$dbfile.pag")) {
	    im_err "history: open $dbfile.pag ($!)\n";
	    return -1;
	}
    }
    if (! &win95p) {
	unless (flock (HIST_FH, LOCK_EX | LOCK_NB)) {
	    im_warn "history: waiting for write lock ($!)\n";
	    unless (flock (HIST_FH, LOCK_EX)) {
		im_err "history: flock ($!)\n";
		return -1;
	    }
	}
    }
    $locked = 1;
    return 0;
}


sub history_close() {
    if ($nodbfile) {
	im_err("no database specified.\n");
	return;
    }
    if (! &win95p) {
	if ($locked) {
	    flock(HIST_FH, LOCK_UN);
	}
    }
    untie %History;
    if ($locked) {
	close(HIST_FH);
    }
    $locked = 0;
}


sub history_lookup($$) {
    if ($nodbfile) {
	im_err("no database specified.\n");
	return ();
    }
    my($msgid, $field) = @_;
    $msgid =~ s/^<(.*)>$/$1/;
    if (defined($History{$msgid})) {
	if ($field == LookUpAll) {
	    return split("\t", $History{$msgid});
	} else {
	    my @flds = split("\t", $History{$msgid});
	    return $flds[$field];
	}
    } else {
	if ($field == LookUpAll) {
	    return ();
	} else {
	    return '';
	}
    }
}

sub history_store($$) {
    if ($nodbfile) {
	im_err("no database specified.\n");
	return -1;
    }
    my($msgid, $folder) = @_;
    $msgid =~ s/^<(.*)>$/$1/;
    im_notice("add to history: $msgid\t$folder\n");
    if (defined($History{$msgid})) {
	my($ofolder) = split("\t", $History{$msgid});
	if (scalar(grep($folder eq $_, split(',', $ofolder)))) {
	    return;
	}
	$folder = "$ofolder,$folder";
    }
    $History{$msgid} = $folder;
}

sub history_delete($$) {
    if ($nodbfile) {
	im_err("no database specified.\n");
	return -1;
    }
    my($msgid, $folder) = @_;
    $msgid =~ s/^<(.*)>$/$1/;
    if (defined($History{$msgid})) {
	if ($folder ne '') {
	    my($f) = split("\t", $History{$msgid});
	    my(@list, $found);
	    foreach (split(',', $f)) {
		if ($_ eq $folder) {
		    $found = 1;
		} else {
		    push(@list, $_)
		}
	    }
	    return -1 unless ($found);
	    if ($#list < 0) {
		delete $History{$msgid};
		return 0;
	    } else {
		$History{$msgid} = join(',', @list);
		return ($#list + 1);
	    }
	} else {
	    delete $History{$msgid};
	    return 0;
	}
    } else {
	return -1;
    }
}


sub history_dump() {
    if ($nodbfile) {
	im_err("no database specified.\n");
	return;
    }
    my($key, $val);
    while (($key, $val) = each(%History)) {
	print "$key\t$val\n";
    }
}

sub history_rename($$$) {
    if ($nodbfile) {im_err("no database specified.\n"); return;}

    my($id, $m1, $m2) = @_;
    $id =~ s/<(.*)>/$1/;

    my $h;
    if (defined $History{$id}) {
	$h = $History{$id};
	$h =~ s/^([^\t]+)(.*)//;
	$h = join(',', grep($_ ne $m1, split(',', $1)), $m2) . $2;
    } else {
	$h = $m2;
	im_warn("no entry for $id, create it.\n");
    }
    $History{$id} = $h if ($History{$id} ne $h);
    return 0;
}

sub history_link($$$) {
    if ($nodbfile) {im_err("no database specified.\n"); return;}

    my($id, $m1, $m2) = @_;
    $id =~ s/<(.*)>/$1/;

    my $h;
    if (defined $History{$id}) {
	$h = $History{$id};
	$h =~ s/^([^\t]+)(.*)//;
	$h = join(',', grep($_ ne $m2, split(',', $1)), $m2) . $2;
    } else {
	$h = $m1 . ',' . $m2;
	im_warn("no entry for $id, create it.\n");
    }
    $History{$id} = $h if ($History{$id} ne $h);
    return 0;
}

sub history_unlink($$) {
    if ($nodbfile) {im_err("no database specified.\n"); return;}

    my($id, $m1) = @_;
    $id =~ s/<(.*)>/$1/;

    if (defined $History{$id}) {
        my $h = $History{$id};
	$h =~ s/^([^\t]+)(.*)//;
	$h = join(',', grep($_ ne $m1, split(',', $1))) . $2;
	if ($History{$id} =~ /^\t/ || !$m1) {
	    delete $History{$id};
	} elsif ($History{$id} ne $h) {
	    $History{$id} = $h;
	}
	return 0;
    }
    im_warn("no message id in $m1\n");
    return -1;
}

1;

__END__

=head1 NAME

IM::History - mail/news history database handler

=head1 SYNOPSIS

 use IM::History;

 history_open($with_lock);
 history_dump();
 history_store($msgid, $folder);
 history_lookup($msgid, LookUpAll);
 history_lookup($msgid, LookUpMsg);
 history_delete($msgid, $folder);
 history_rename($id, $m1, $m2);
 history_link($id, $m1, $m2);
 history_close();

=head1 DESCRIPTION

The I<IM::History> module handles mail/news database.

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
