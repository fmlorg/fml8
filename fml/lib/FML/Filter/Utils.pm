#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Utils.pm,v 1.1.1.1 2001/03/28 15:13:31 fukachan Exp $
#

package FML::Filter::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::Utils - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 C<clean_up_buffer($args)>

remove some special syntax pattern for further check.
For example, the pattern is a mail address.
We remove it and check the remained buffer whether it is safe or not.

=cut

sub clean_up_buffer
{
    my ($self, $xbuf) = @_;

    # 1. cut off Email addresses (exceptional).
    $xbuf =~ s/\S+@[-\.0-9A-Za-z]+/account\@domain/g;

    # 2. remove invalid syntax seen in help file with the bug? ;D
    $xbuf =~ s/^_CTK_//g;
    $xbuf =~ s/\n_CTK_//g;

    $xbuf;
}


=head2 C<is_one_line($args)>

=cut


sub is_one_line
{
    my ($self, $buf) = @_;

    local(*e, *pmap, $lparbuf) = @_;
    my($one_line_check_p) = 0;
    my($n_paragraph) = $#pmap;

    &Log("OneLineCheckP: n_paragraph=$n_paragraph") if $main::debug;

    if ($n_paragraph == 1) { $one_line_check_p = 1;}
    if ($n_paragraph == 2) { 
	my($buf) = &main::STR2EUC($lparbuf);
	my($pat); 
	if ($buf =~ /(\n.)/) { $pat = $1;}

	# basic citation ?
	if ($buf =~ /\n>/) {
	    &Log("/^>/ lines! must be citation") if $main::debug;
	    &Log("2 paragraphs but accept mail as citation");
	}
	# more functional citation ?:)
	# Oops ;-) This mail body is also a citation ;-) in this logic;)
	#   Kenken
	#   Kaisha
	# 
	elsif ($pat && ($buf =~ /$pat.*$pat/)) {
	    my ($p) = $pat;
	    $p =~ s/\n//;
	    &Log("plural /^$p/ lines! must be citation") if $main::debug;
	    &Log("2 paragraphs but accept mail as citation");
	}
	elsif ($lparbuf =~ /\@/ || 
	    $lparbuf =~ /TEL:/i ||
	    $lparbuf =~ /FAX:/i ||
	    $lparbuf =~ /:\/\// ) {
	    &Log("2 paragraphs and 2nd one may be the signature");
	    $one_line_check_p = 1; 
	}
	# account"2-byte @"domain where "@" is a 2-byte "@" character.
	elsif ($buf =~ /[-A-Za-z0-9]\241\367[-A-Za-z0-9]/) {
	    &Log("2 paragraphs and 2nd one may be the signature (2-byte \@)");
	    $one_line_check_p = 1;
	}
    }

    $one_line_check_p;
}


# XXX fml 4.0: EUCCompare($buf, $pat) 
# XXX          where $pat should be $& (matched pattern)
sub euc_compare
{
    my ($self, $a, $pat) = @_;

    # (Refeence: jcode 2.12)
    # $re_euc_c    = '[\241-\376][\241-\376]';
    # $re_euc_kana = '\216[\241-\337]';
    # $re_euc_0212 = '\217[\241-\376][\241-\376]';
    my ($re_euc_c, $re_euc_kana, $re_euc_0212);
    $re_euc_c    = '[\241-\376][\241-\376]';
    $re_euc_kana = '\216[\241-\337]';
    $re_euc_0212 = '\217[\241-\376][\241-\376]';

    # always true if given buffer is not EUC.
    if ($a !~ /($re_euc_c|$re_euc_kana|$re_euc_0212)/) {
	&Log("EUCCompare: do nothing for non EUC strings") if $debug;
	return 1;
    }

    # extract EUC code (e.g. .*EUC_PATTERN.*)
    # but how to do for "EUC ASCII EUC" case ???
    my ($pa, $loc, $i);
    do {
	if ($a =~ /(($re_euc_c|$re_euc_kana|$re_euc_0212)+)/) {
	    $pa  = $1;
	    $loc = index($pa, $pat);
	}

	print "buf = <$a> pa=<$pa> pat=<$pat> loc=$loc\n";

	return 1 if ($loc % 2) == 0;

	$a = substr($a, index($a, $pa) + length($pa) );
    } while ($i++ < 16);

    0;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Filter::Utils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
