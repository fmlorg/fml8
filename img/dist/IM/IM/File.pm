# -*-Perl-*-
################################################################
###
###                           File.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Jul  7, 1997
### Revised: Feb 28, 2000
###

my $PM_VERSION = "IM::File.pm version 20000228(IM140)";

package IM::File;
require 5.003;
require Exporter;

use IM::Config qw(expand_path mail_path news_path msgdbfile);
use IM::Util;
use File::Copy;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(im_rename im_link im_unlink);

## im_rename(path1, path2);
## im_link  (path1, path2);
## im_unlink(path1);
##
## paths may be full-path or [+=]folder../../message.

use vars qw($CHECKED $USE_DB);

sub im_rename ($$) {
    my ($p1, $p2) = @_;
    my ($m1, $m2);
    my ($ret);
    ($p1, $m1) = expand_path_and_msg($p1);
    ($p2, $m2) = expand_path_and_msg($p2);

    #my ($id) = get_msg_info($p1) if (!defined $id && !$main::opt_noharm);
    #XXX???
    my ($id);
    if (defined($main::id) || $main::opt_noharm) {
	$id = $main::id;
    } else {
	$id = get_msg_info($p1);
    }

    if ($main::opt_noharm) {
	print "mv $p1 $p2\n";
	$ret = 1;
    } else {
	if (!($ret = rename($p1, $p2))){
	    $ret = copy($p1, $p2) && unlink($p1);
	}
	history_rename($id, $m1, $m2)
	    if (USE_DB() && $ret && $id);
    }
    return $ret;
}

sub im_link ($$) {
    my ($p1, $p2) = @_;
    my ($m1, $m2);
    my ($ret);
    ($p1, $m1) = expand_path_and_msg($p1);
    ($p2, $m2) = expand_path_and_msg($p2);

    #my ($id) = get_msg_info($p1) if (!defined $id && !$main::opt_noharm);
    my ($id);
    if (defined($main::id) || $main::opt_noharm) {
	$id = $main::id;
    } else {
	$id = get_msg_info($p1);
    }

    if ($main::opt_noharm) {
	print "ln $p1 $p2\n";
	$ret = 1;
    } else {
	if (win95p() || os2p() || wntp() || !($ret = link($p1, $p2))){
	    $ret = copy($p1, $p2);
	}
	history_link($id, $m1, $m2)
	    if (USE_DB() && $ret && $id);
    }
    return $ret;
}

sub im_unlink ($)
{
    my ($p1) = @_;
    my ($m1, $ret);

    ($p1, $m1) = expand_path_and_msg($p1);

    # my ($id) = get_msg_info($p1) if (!defined $id && !$main::opt_noharm);
    my ($id);
    if (defined($main::id) || $main::opt_noharm) {
	$id = $main::id;
    } else {
	$id = get_msg_info($p1);
    }

    if ($main::opt_noharm || $main::opt_verbose) {
	print "unlink $p1\n";
	$ret = 1;
    }
    if (!$main::opt_noharm) {
	$ret = unlink($p1);
	history_delete($id, $m1)
	    if (USE_DB() && $ret && $id);
    }
    return $ret;
}

#################################################################
##
## Private.
##
sub get_msg_info ($)
{
    my ($p, $m) = expand_path_and_msg(shift);
    my ($id, $date, $hdr);
    local $/ = '';

    if (im_open(\*MSG, "<$p")){
        $hdr = <MSG>;  close(MSG);
    } else {
	im_warn("no message id in $m.\n");
        return undef;
    }
    ($id) = ($hdr =~ /^message-id:\s*(<[^>\n]*>)/mi);
    im_warn("no message-id in $m.\n") if (!$id);

#   ($date) = ($hdr =~ /^date:\s*([^\n]*)/mi);
#   im_warn("no date field  $m.\n") if (!$date);

#   return ($id, $date|| gmtime((stat($p))[9]) . " +0000");
    return ($id);
}

sub unexpand_path ($) {
    my $path = shift;
    my ($mail_path, $news_path) = (mail_path(), news_path());

    $path =~ s!^$mail_path/*!\+!;
    $path =~ s!^$news_path/*!\=!;

    return $path;
}

sub expand_path_and_msg ($) {
    my $path_or_msg = shift;
    return (expand_path($path_or_msg), unexpand_path($path_or_msg));
}

sub USE_DB () {
    if (!$CHECKED) {
	$CHECKED = 1;
	if ($USE_DB = msgdbfile()) {
	    require IM::History;
	    import IM::History qw(history_open history_delete
				  history_rename history_link);
	    history_open(1);
	}
    }
    return $USE_DB;
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
