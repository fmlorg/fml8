# -*-Perl-*-
################################################################
###
###			       Alias.pm
###
### Author:  Internet Message Group <img@mew.org>
### Created: Apr 23, 1997
### Revised: Feb 28, 2000
###

my $PM_VERSION = "IM::Alias.pm version 20000228(IM140)";

package IM::Alias;
require 5.003;
require Exporter;

use IM::Config qw(expand_path aliases_file addrbook_file);
use IM::Util;
use integer;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(alias_read alias_lookup alias_print
	     hosts_read hosts_completion hosts_lookup hosts_print);

=head1 NAME

Alias - mail and host alias looking up package

=head1 SYNOPSIS

  use IM::Alias;

  alias_read(mail_alias_files, addrbook_files);
  $result = alias_lookup(user_name);
  alias_print(alias);

  hosts_read(hosts_alias_files);
  $result = hosts_completion(mail_address);
  hosts_print(alias);

=head1 DESCRIPTION

  alias_read("$HOME/.im/Aliases", "$HOME/.im/Addrbook");
  hosts_read("$HOME/.hostaliases");

  $result = alias_lookup('u');
  print "$result\n" if ($result);

  $result = hosts_completion('u@h');
  print "$result\n" if ($result);

  alias_print("a") displays mail addresses whose alias is "a".
  hosts_print("") displays all host aliases.

=cut

use vars qw(%MAIL_ALIAS_HASH %MAIL_ALIASES %HOST_ALIASES);

##### READ MAIL ALIAS FILES #####
#
# alias_read($mail_aliases_files, $addrbook_files)
#
#	return value: none
#
sub alias_read (;$$) {
    my @olds = split(',', shift || aliases_file());
    my @news = split(',', shift || addrbook_file());
    my $usenew = 0;
    my @aliases;
    my $ali;

    foreach $ali (@news) {
	$ali = expand_path($ali);
	if (-r $ali) {
	    $usenew = 1;
	    last;
	 }
    }
    
    if ($usenew == 1) {
	@aliases = @news;
    } else {
	@aliases = @olds;
    }
 
    %MAIL_ALIASES = ();
    %MAIL_ALIAS_HASH = ();
    ALI: foreach $ali (@aliases) {
	$ali = expand_path($ali);

	if ($MAIL_ALIAS_HASH{$ali}) {
	    im_notice("already opened mail-aliases file: $ali\n");
	    next;
	}

	unless (open(ALIAS, "<$ali")) {
	    im_notice("can't open mail-aliases file: $ali, ignored.\n");
	    next;
	}

	im_debug("mail alias file $ali opened\n") if &debug('alias');
	$MAIL_ALIAS_HASH{$ali} = 1;

	my $line;
	while (defined($line = <ALIAS>)) {
	    next if ($line =~ /^[\#;]/);
	    # xxx Mew allows # in the middle of line.
	    # because of non-ASCII, IM can't support it
	    next if ($line =~ /^\s*$/);
	    chomp($line);
	    if ($line =~ /^<\s*(\S+)$/) {
		push(@aliases, $1);
		next;
	    }
	    $line =~ s/^\s+//;
	    if ($line =~ /^\S+[:=]/) {
		my $cont;
		while ($line =~ /\\$/) {
		    chop($line);
		    unless (defined($cont = <ALIAS>)) {
			im_warn("EOF encountered on the entry: $line.\n");
			next ALI;
		    }
		    chomp($cont);
		    $cont =~ s/^\s*/ /;
		    $line .= $cont;
		}
		my ($name, $val) = split('\s*[:=]\s*', $line, 2);
		$MAIL_ALIASES{$name} = $val if $val;
	    } else {
		#personal info. Skip continuous lines.
		while ($line =~ /\\$/) {
		    $line = <ALIAS>;
		    unless (defined($line)) {
			next ALI;
		    }
		}
	    }
	}
	close(ALIAS);
    }
}

##### USER LEVEL ALIAS LOOKUP #####
#
# alias_lookup(alias)
#	alias: an alias to be looked up
#	return value: aliased address OR null
#
sub alias_lookup ($) {
    my $alias = shift;
    return '' if ($alias =~ /[\@%!:]/o);

    im_debug ("looking up alias for $alias\n") if &debug ('alias') ;
    my $addr = $MAIL_ALIASES{$alias};
    if ($addr) {
	im_debug("found $alias -> $addr\n") if &debug('alias');
	return $addr;
    }
    return '';
}

##### PRINT ALL MAIL ALIAES #####
#
# alias_print(alias)
#       alias: an alias to be looked up
#       return value: none
#
sub alias_print (;$) {
    my $alias = shift;

    if ($alias) {
	im_debug("searching $alias.\n") if (&debug('alias'));
 	if ($MAIL_ALIASES{$alias}) {
	    print "$alias: $MAIL_ALIASES{$alias}\n";
	}
    } else {
	my $key;
	foreach $key (sort keys %MAIL_ALIASES) {
	    print "$key: $MAIL_ALIASES{$key}\n";
	}
    }
}

##### READ HOST ALIAS FILES #####
#
# hosts_read($host_aliases)
#
#	return value: none
#
sub hosts_read (;$) {
    my @aliases = split(',', shift || '~/.hostaliases');
    my $ali;

    %HOST_ALIASES = ();
    foreach $ali (@aliases) {
 	$ali = expand_path($ali);

	unless (open(ALIAS, "<$ali")) {
	    im_notice("can't open host-aliases file: $ali, ignored.\n");
	    next;
	}
	im_debug("host alias file $ali opened\n") if &debug('alias');

	my $line;
	while (defined($line = <ALIAS>)) {
	    $line =~ s/#.*//;
	    if ($line =~ /([\w.-]+)\s+([\w.-]+)/) {
		$HOST_ALIASES{$1} = $2;
	    }
	}
	close(ALIAS);
    }
}

##### USER LEVEL ADDRESS COMPLETION #####
#
# hosts_completion(address)
#	address: an address to be tried completion
#       cmpl: flag whether complete with get_host_byname() or not;
#	return value: completed address OR null
#
sub hosts_completion ($;$) {
    my ($addr, $cmpl) = @_;

    if ($addr =~ /^([\w-.]+)@([\w-.]+)$/) {
	my ($local, $domain) = ($1, $2);
	im_debug("searching $domain by host alias file.\n") if &debug('alias');
	my $new = $HOST_ALIASES{$domain};
	if ($new) {
	    im_debug("found(file): $domain -> $new\n") if (&debug('alias'));
	    return "$local\@$new";
	}
	if ($cmpl) {
	    im_debug("searching $domain with gethostbyname().\n")
		if (&debug('alias'));
	    my ($he_name) = gethostbyname($domain);
	    if (length($he_name) > length($domain)) {
		im_debug("found(gethostbyname): $domain -> $he_name\n")
		    if (&debug('alias'));
		return "$local\@$he_name";
	    }
	}
    }
    return '';
}

##### USER LEVEL HOSTS LOOKUP #####
#
# hosts_lookup(alias)
#	alias: an alias to be looked up
#	return value: aliased hosts OR null
#
sub hosts_lookup ($) {
    my $alias = shift;
    my $host = $HOST_ALIASES{$alias};
    if ($host) {
	im_debug("found $alias -> $host\n") if &debug('alias');
	return $host;
    }
    return '';
}

##### PRINT ALL HOSTS ALIAES #####
#
# hosts_print(alias)
#       alias: an alias to be looked up
#       return value: none
#
sub hosts_print (;$) {
    my $alias = shift;

    if ($alias) {
	im_debug("searching $alias.\n") if (&debug('alias'));
 	if ($HOST_ALIASES{$alias}) {
	    print "$alias\t$HOST_ALIASES{$alias}\n";
	}
    } else {
	my $key;
	foreach $key (sort keys %HOST_ALIASES) {
	    print "$key\t$HOST_ALIASES{$key}\n";
	}
    }
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
