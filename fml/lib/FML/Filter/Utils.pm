#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
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
