# -*-Perl-*-
################################################################
###
###                          Recipient.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 27, 1997
### Revised: Mar 22, 2003
###

my $PM_VERSION = "IM::Recipient.pm version 20030322(IM144)";

package IM::Recipient;
require 5.003;
require Exporter;

use IM::Util;
use IM::Address qw(extract_addr fetch_addr);
use IM::Alias qw(alias_lookup hosts_completion);
use IM::Config qw(expand_path);

# use FileHandle;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(add_to_rcpt parse_rcpt rcpt_pickup);

use vars qw($Alias_match_count $Include_count %Include_Files);
##### ADD AN ADDRESS TO RECIPIENT LIST #####
#
# add_to_rcpt(bcc_flag, addr)
#	bcc_flag: register with "bcc" tag
#	addr: an address to be registered
#	return value: none
#	   0: success
#	  -1: failure
#
sub add_to_rcpt($$) {
    my($bcc_flag, $addr) = @_;
    my($rec, $a);
    $addr = &extract_addr($addr);
    return -1 if ($addr eq '');
    return 0 unless ($addr);
    if ($addr =~ /^\@MYSELF\@/i || $addr =~ /^\@ME\@/i) {
	$addr = $main::Sender;
    }
    if ($addr !~ /[\@%!:]/o) {
	if (($a = alias_lookup($addr)) ne '') {
	    if ($Alias_match_count++ == 100) {
		&im_warn("May be alias loop: $addr\n");
		return -1;
	    }
	    if (&parse_rcpt($bcc_flag, $a, 1) < 0) {
		return -1;
	    } else {
		return 0;
	    }
	} elsif (!$main::Obey_MTA_domain && $main::Default_to_domain_name) {
	    $addr .= "\@$main::Default_to_domain_name";
	}
    } elsif ($a = hosts_completion($addr, $main::Cmpl_with_gethostbyname)) {
	$addr = $a;
    }
    # duplicate surpression
    foreach $rec (@main::Recipients) {
	if ($bcc_flag) {
	    return 0 if ($rec eq $addr);
	} else {
	    return 0 if ($rec eq "<$addr>");
	}
    }
    im_debug("adding to recipients: <$addr>\n") if (&debug("rcpt"));
    $addr = "<$addr>" unless ($bcc_flag);
    push (@main::Recipients, $addr);
    return 0;
}

##### PARSE RECIPIENT LIST #####
#
# parse_rcpt(bcc_flag, addr_list, need_code_conversion)
#	bcc_flag:
#		 1 = BCC distination
#		 0 = normal distination
#		-1 = parse only
#	addr_list: address list string (concatinated with ",")
#	return value: number of addresses in the list (-1 if error)
#
sub parse_rcpt($$$) {
    my($bcc_flag, $addr_list, $conv) = @_;
    my($cnt, $addr);
    $addr_list =~ s/^\s+//;
    $addr_list =~ s/\n\s*//g;	# XXX
    return 0 if ($addr_list eq '');

## if ISO2022JP
    if ($conv) {
	if ($main::Iso2022jp_code_conversion) {
	    require IM::Japanese;
	    import IM::Japanese qw(conv_iso2022jp);
	    $addr_list = conv_iso2022jp($addr_list);
	}
	if ($main::Iso2022jp_header_mime_conv) {
	    require IM::Iso2022jp;
	    import IM::Iso2022jp qw(struct_iso2022jp_mimefy);

	    my $a = &struct_iso2022jp_mimefy($addr_list);
	    return -1 if ($a eq '');
	    $addr_list = $a;
	}
    }
## endif

    $cnt = 0;
    while ($addr_list ne '') {
	($addr, $addr_list) = &fetch_addr($addr_list, 1);
	return -1 if ($addr eq '');
	if ($bcc_flag >= 0) {
	    if ($addr =~ /^.+:[^;]*;$/) {	# YYY
		return -1 if (&expn_group($bcc_flag, $addr) < 0);
	    } else {
		return -1 if (&add_to_rcpt($bcc_flag, $addr) < 0);
	    }
	}
	$cnt++;
	$addr_list =~ s/^\s*//;
    }
    return $cnt;
}

##### EXPAND GROUP/LIST SYNTAX #####
#
# expn_group(bcc_flag, group_syntax_address)
#	bcc_flag: need "bcc" style message format if true
#	group_syntax_address: an gruop:addrs; style address to be expanded
#	return value:
#	   0: success
#	  -1: failure
#
sub expn_group($$) {
    my($bcc_flag, $group_expression) = @_;
    my($rest, @mboxes, $rec);
#   return if ($group_expression !~ /:.*;$/);
    return if ($group_expression !~ /:[^;]*;/);
    im_debug("expanding $group_expression\n") if (&debug('rcpt'));
#   my($group_name);
#   $group_name = $group_expression;
#   $group_name =~ s/:.*/:;/;
    $rest = $group_expression;
    $rest =~ s/.+:([^;]*);$/$1/;	# YYY
    @mboxes = split (',', $rest);
    foreach $rec (@mboxes) {
	if ($rec !~ /\@/
	  && ($rec =~ /^\// || $rec =~ /^\~/ || $rec =~ /^\w:\//)) {
	    &expn_rcpt_list($bcc_flag, $rec);
	} else {
	    return -1 if (&add_to_rcpt($bcc_flag, $rec) < 0);
	}
    }
#   return $group_name;
    return 0;
}

##### INCLUDE RECIPIENT LIST FILE #####
#
# expn_rcpt_list(bcc_flag, include_file)
#	bcc_flag: need "bcc" style message format if true
#	include_file: path of an address list file to be included
#	return value:
#	  0: success
#	 -1: failure
#
sub expn_rcpt_list($$) {
    my($bcc_flag, $include_file) = @_;
    my($file) = &expand_path($include_file);
    my($INCLUDE) = &include_open($file);
    if ($INCLUDE) {
	while (defined($_ = include_readline($INCLUDE))) {
	    chomp;
	    im_debug("reading $file: $_\n")
	      if (&debug('include'));
	    next if (/^#/);
	    s/\s#@#.*//;
	    s/\s*$//;
	    if (/^\s*:include:/) {
		if ($Include_count++ == 100) {
		    im_err("May be include loop: $_\n");
		    return -1;
		}
		s/^\s*:include://;
		# my $hdl = *INCLUDE;	# save for reccursive
		&expn_rcpt_list($bcc_flag, $_);
		# *INCLUDE = $hdl;
	    } elsif (/^\s*\//) {
		im_err("Mail to file not supported: $_\n");
		return -1;
	    } elsif (/^\s*\|/ || /^\s*"\s*\|/) {  #"
		im_err("Mail to program not supported: $_\n");
		return -1;
	    }
	    return -1 if (&parse_rcpt($bcc_flag, $_, 0) < 0);
	}
	include_close($INCLUDE);
    } else {
	im_err("List file $file not found\n");
	return -1;
    }
    return 0;
}

##### PICK UP RECIPIENTS FROM HEADER #####
#
# rcpt_pickup(header, resend_flag, news_only_flag)
#	resend_flag: pickup addresses for redistributing mode
#	news_only_flag: do not pickup destination addresses for news mode
#	return value:
#	  -1: failure
#	   0: success
#
sub rcpt_pickup($$$) {
    my($Header, $resend_flag, $news_only_flag) = @_;
    my $line;
    my $resend_prefix;

    foreach $line (@$Header) {
	if ($line =~ /^Fcc:(.*)/is) {
	    $main::Fcc_folder = $1;
	    $main::Fcc_folder =~ s/\s//g;
	}
	if ($news_only_flag) {
	    if ($line =~ /^Dcc:(.*)/is) {
		return -1 if (&parse_rcpt(0, $1, 0) < 0);
	    } elsif ($line =~ /^Bcc:(.*)/is) {
		return -1 if (&parse_rcpt($main::Mime_bcc, $1, 0) < 0);
	    }
	} else {
	    $resend_prefix = $resend_flag ? "Resent-" : "";
	    if ($line =~ /^${resend_prefix}(To|Cc|Dcc):(.*)/is) {
		return -1 if (&parse_rcpt(0, $2, 0) < 0);
	    } elsif ($line =~ /^${resend_prefix}Bcc:(.*)/is) {
		return -1 if (&parse_rcpt($main::Mime_bcc, $1, 0) < 0);
	    }
	}
    }
    return 0;
}

##### OPEN A INCLUDE FILE WITH NEW FILE HANDLE #####
#
# include_open(file_name, handle_name)
#       return value: handle
#
no strict 'refs';
sub include_open($) {
    my($file) = shift;
    return undef if $Include_Files{$file};
    im_open($file, $file) || return undef;
    $Include_Files{$file} = 1;
    return $file;
}
sub include_readline($) {
    my $fh = shift;
    return scalar(<$fh>);
}
sub include_close($) {
    my($fh) = shift;
    close($fh);
    delete $Include_Files{$fh};
}

1;

__END__

=head1 NAME

IM::Recipient - mail/news recipient handler

=head1 SYNOPSIS

 use IM::Recipient;

 add_to_rcpt(bcc_flag, addr)
     bcc_flag: register with "bcc" tag
     addr: an address to be registered
     return value: none
	  0: success
	 -1: failure

 parse_rcpt(bcc_flag, addr_list, need_code_conversion)
     bcc_flag:
	  1 = BCC distination
	  0 = normal distination
	 -1 = parse only
     addr_list: address list string (concatinated with ",")
     return value: number of addresses in the list (-1 if error)

 rcpt_pickup(header, resend_flag, news_only_flag)
     resend_flag: pickup addresses for redistributing mode
     news_only_flag: do not pickup destination addresses for news mode
     return value:
	 -1: failure
	  0: success

=head1 DESCRIPTION

The I<IM::Recipient> module handles recipient of mail/news message.

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
