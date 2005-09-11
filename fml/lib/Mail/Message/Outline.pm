#-*- perl -*-
#
# Copyright (C) 2005 Ken'ichi Fukamachi
#
# $FML$
#

package Mail::Message::Outline;
use strict;
use Mail::Message::Language::Japanese::Outline;

=head1 NAME

Mail::Message::Outline - handle outline or outline.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: create outine / summary.
#    Arguments: OBJ($self) HASH_REF($params)
# Side Effects: none
# Return Value: STR
sub outline
{
    my ($self, $params) = @_;
    my $header = $self->whole_message_header();
    my $msg    = $self->find_first_plaintext_message();
    my $result = '';

    # options
    my $is_hdr = $params->{ with_header } || 'yes';
    my $is_msg = 1;

    # 1. prepend subject.
    if ($is_hdr eq 'yes' && defined $header) {
	use Mail::Message::String;
	my $subject = $header->get('subject') || '';
	if ($subject =~ /=\?/o) {
	    my $string  = new Mail::Message::String $subject;
	    $string->mime_decode();
	    $string->charcode_convert_to_internal_code();
	    $result .= $string->as_str();
	}
	else {
	    $result .= $subject;
	}
    }

    # 2. summarize message to a few lines.
    if ($is_msg && defined $msg) {
	my $prgbuf = '';
	my $found  = 0;
	my $max    = $params->{ summary_max_lines } || 3;
	my $np     = $msg->num_paragraph();

      PARAGRAPH:
	for my $i (1 .. $np) {
	    $prgbuf = $msg->nth_paragraph($i);

	  LINE:
	    for my $buf (split(/\n/, $prgbuf)) {
		if ($buf && $self->_is_useful_for_summary($buf)) {
		    $result .= "   $buf\n";
		    $found++;
		}

		last PARAGRAPH if $found >= $max;
	    }
	}
    }

    return $result;
}


# Descriptions: check if $buf looks effective string e.g. not quote ?
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_useful_for_summary
{
    my ($self, $buf) = @_;

    # ignore empty line.
    return 0 if $buf =~ /^\s*$/o;

    # ignore string similar to quote.
    return 0 if $self->_is_citation_or_signature($buf);

    # ignore mail header like patterns.
    return 0 if $buf =~ /^X-[-A-Za-z0-9]+:/io;
    return 0 if $buf =~ /^Return-[-A-Za-z0-9]+:/io;
    return 0 if $buf =~ /^Mime-[-A-Za-z0-9]+:/io;
    return 0 if $buf =~ /^Content-[-A-Za-z0-9]+:/io;
    return 0 if $buf =~ /^(To|From|Subject|Reply-To|Received):/io;
    return 0 if $buf =~ /^(Message-ID|Date):/io;

    # o.k.
    return 1;
}


# Descriptions: check if $buf looks not effective string e.g. quote ?
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_citation_or_signature
{
    my ($self, $buf) = @_;

    use Mail::Message::String;
    my $string = new Mail::Message::String $buf;
    $string->charcode_convert_to_internal_code();
    return 1 if $string->is_citation();
    return 1 if $string->is_signature();

    my $str = $string->as_str();
    if ($str =~ /^[\>\#\|\*\:\;\=]/o) {
	return 1;
    }
    elsif ($str =~ /^in /o) { # citation ?
	return 1;
    }
    elsif ($str =~ /^\w+.*wrote:/io) { # citation.
	return 1;
    }
    elsif ($str =~ /\w+\@\w+/o) { # mail address ?
	return 1;
    }
    elsif ($str =~ /^\S+\>/o) { # citation ?
	return 1;
    }
    elsif ($str =~ /^hi|^hi,/io) { # self introduction.
	return 1;
    }

    return 0;
}


=head2 has_closing_phrase()

check if this message has closing phrase in it.

=head2 set_closing_phrase_rules($rules)

set rules.

=head2 get_closing_phrase_rules()

get rules.

=cut


# Descriptions: check if this message has closing phrase in it.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub has_closing_phrase
{
    my ($self)  = @_;
    my $msg     = $self->find_first_plaintext_message();
    my $rules   = $self->get_closing_phrase_rules();
    my $regexp  = join("|", keys %$rules);

    if (defined($msg) && $regexp) {
	my ($buf, $string);

	my $num_prg = $msg->num_paragraph();
	for (my $i = 1; $i <= $num_prg; $i++) {
	    $buf = $msg->nth_paragraph($i);
	    $buf =~ s/^[\s\n]*//o;
	    $buf =~ s/[\s\n]*$//o;

	    if ($buf) {
		$string = new Mail::Message::String $buf;
		$string->charcode_convert_to_internal_code();
		$buf = $string->as_str();
		if ($buf =~ /$regexp/) { return 1;}
	    }
	}
    }

    return 0;
}


# Descriptions: set phrase trap rules.
#    Arguments: OBJ($self) HASH_REF($rules)
# Side Effects: update $self.
# Return Value: none
sub set_closing_phrase_rules
{
    my ($self, $rules) = @_;

    if (defined $rules) {
	$self->{ _closing_phrase_rules } = $rules || {};
    }
}


# Descriptions: return phrase trap rules.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_closing_phrase_rules
{
    my ($self) = @_;
    my $rules  = $self->{ _closing_phrase_rules } || {};

    return $rules;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Outline first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
