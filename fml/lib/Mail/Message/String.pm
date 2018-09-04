#-*- perl -*-
#
#  Copyright (C) 2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: String.pm,v 1.9 2004/07/23 15:59:16 fukachan Exp $
#

package Mail::Message::String;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $debug);
use Carp;
use Mail::Message::Encode::Perl;

$debug = 0;


=head1 NAME

Mail::Message::String - base class of string used in message (header).

=head1 SYNOPSIS

    use Mail::Message::String $subject;
    my $sbj = new Mail::Message::String $subject;
    $sbj->mime_header_decode();

     ... delte tag et.al. ...

    $sbj->mime_header_encode();
    $subject = $sbj->as_str();

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $str) = @_;
    my ($type) = ref($self) || $self;

    # init
    $str ||= '';

    my $me = {};
    set($me, $str);
    bless $me, $type;

    # save hints for further use.
    $me->{ _orig_string }       = $str;
    $me->{ _orig_mime_charset } = $me->get_mime_charset();

    return bless $me, $type;
}


=head2 set($str)

initialize data in this object.

=head2 get()

get (converted) data in this object as string (same as as_str()).

=cut


# Descriptions: set string data in this object.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: OBJ
sub set
{
    my ($self, $str)   = @_;
    $self->{ _string } = $str;
}


# Descriptions: get string data in this object as string (same as as_str()).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub get
{
    my ($self) = @_;
    $self->as_str();
}


=head2 as_str()

return data (converted data) as string.

=cut


# Descriptions: return data (converted data) as string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub as_str
{
    my ($self) = @_;

    return( $self->{ _string } || '' );
}


=head1 MIME related utilities

=head2 mime_encode($encode, $out_code, $in_code)

mime encode this object and return the encoded string.

=head2 mime_decode($out_code, $in_code)

mime decode this object and return the decoded string.

=head2 set_mime_charset($charset)

dummy now.

=head2 get_mime_charset()

return charset information.

=cut


# Descriptions: MIME encode of string.
#    Arguments: OBJ($self) STR($encode) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub mime_encode
{
    my ($self, $encode, $out_code, $in_code) = @_;
    my $str = $self->as_str();

    # base64 encoding by default.
    $encode   ||= 'base64';

    # speculate charset by a few hints.
    $out_code ||= $self->_speculate_external_charset();

    if ($debug) {
	print "\tencode($str, $encode, $out_code, $in_code)\n";
    }

    # XXX-TODO: we cannot mime-encode non iso-2022-jp string.
    use Mail::Message::Encode;
    my $obj = new Mail::Message::Encode;
    $str    = $obj->encode_mime_string($str, $encode, $out_code, $in_code);
    $self->set($str);

    return $str;
}


# Descriptions: decode MIME string.
#    Arguments: OBJ($self) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub mime_decode
{
    my ($self, $out_code, $in_code) = @_;
    my $str = $self->as_str();

    use Mail::Message::Encode;
    my $encode  = new Mail::Message::Encode;
    my $dec_string = $encode->decode_mime_string($str, $out_code, $in_code);
    $self->set($dec_string);

    return $dec_string;
}


# Descriptions: dummy now.
#               enforce charset to handle.
#    Arguments: OBJ($self) STR($charset)
# Side Effects: none
# Return Value: none
sub set_mime_charset
{
    my ($self, $charset) = @_;

}


# Descriptions: return charset information.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_mime_charset
{
    my ($self) = @_;
    my $str    = $self->as_str();

    if ($str =~ /\=\?([-\w\d]+)\?/o) {
	my $charset = $1;
	$charset =~ tr/A-Z/a-z/;
	return $charset;
    }
    else {
	return '';
    }
}


=head2 mime_header_encode()

encode the given Perl internal UTF8 format to 
the MIME Header string and return the encoded message.

=head2 mime_header_decode()

decode MIME Header string and return the decoded message
as Perl internal UTF8 format.

=cut

# Descriptions: encode the given Perl internal UTF8 format to
#               the MIME Header string and return the encoded message.
#    Arguments: OBJ($self) STR($pif_str)
# Side Effects: none
# Return Value: STR
sub mime_header_encode
{
    my ($self, $pif_str) = @_;
    my $str = $self->as_str();

    use Mail::Message::Encode::Perl;
    my $encoder = new Mail::Message::Encode::Perl;
    $str        = $encoder->mime_header_encode($str);
    $self->set($str);
    
    return $str;
}


# Descriptions: decode MIME Header string and return the decoded message
#               as Perl internal UTF8 format.
#    Arguments: OBJ($self) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR(Perl Internal Format)
sub mime_header_decode
{
    my ($self, $out_code, $in_code) = @_;
    my $str = $self->as_str();

    use Mail::Message::Encode::Perl;
    my $encoder     = new Mail::Message::Encode::Perl;
    my $dec_pif_str = $encoder->mime_header_decode($str);
    $self->set($dec_pif_str);
    
    return $dec_pif_str;
}


=head1 CHAR CODE CONVERSION UTILITIES

We need to identify internal and external char codes in fml8.
It is defined in C<Mail::Message::Charset>.

For example, if the original data is "=?iso-2022-jp?....", external
code is "iso-2022-jp" but internal code is "euc-jp".

=head2 charcode_convert($out_code, [$in_code])

convert charactor code to $out_code and return it.

if $in_code is given, it is used as a hint.
if $in_code is not given, speculate the code.

if $out_code is not given, try to resolve the out code
based on the initial data (e.g. =?ISO-2022-JP? part).

=head2 charcode_convert_to_internal_code().

convert (internal) string to code internally used in fml8.
same as charcode_convert() in fact.

=head2 charcode_convert_to_external_charset()

convert (internal) string to code externally used in fml8.
It implies original code almot cases.

We should ignore the original mime chaset in some cases. For example,
consider invalid "=?sjis? ..." mime string is given. How should we do?

In fact, this module return the mime encoded string as iso-2022-jp
(valid) not original sjis (invalid) charset.

=cut


# Descriptions: convert charactor code to $out_code and return it.
#               if $in_code is given, it is used as a hint.
#               if $out_code is not given, coverted to internal char code.
#    Arguments: OBJ($self) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub charcode_convert
{
    my ($self, $out_code, $in_code) = @_;
    my $str = $self->as_str();

    # speculate internal code we should use for this string.
    $out_code ||= $self->_speculate_internal_code();

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    $encode->convert_str_ref(\$str, $out_code, $in_code);
    $self->set($str);
    return $str;
}


# Descriptions: convert charactor code to internal code.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub charcode_convert_to_internal_code
{
    my ($self) = @_;

    my $out_code = $self->_speculate_internal_code();
    $self->charcode_convert($out_code);
}


# Descriptions: convert charactor code to external code, which is original.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub charcode_convert_to_external_charset
{
    my ($self) = @_;

    my $out_code = $self->_speculate_external_charset();
    $self->charcode_convert($out_code);
}


=head2 get_charcode($str)

regturn char code of $str.

=cut


# Descriptions: get char code of $str.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: STR
sub get_charcode
{
    my ($self, $str) = @_;

    # init
    $str ||= $self->as_str();

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    return $encode->detect_code($str);
}


# Descriptions: speculate internal code to handle in fml.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub _speculate_internal_code
{
    my ($self) = @_;
    my $hint_code = $self->{ _orig_mime_charset };

    # speculate fml internal code: iso-2022-jp -> euc-jp.
    use Mail::Message::Charset;
    my $charset  = new Mail::Message::Charset;
    my $language = $charset->message_charset_to_language($hint_code);
    return $charset->language_to_internal_charset($language);
}


# Descriptions: speculate public charset to handle.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub _speculate_external_charset
{
    my ($self)    = @_;
    my $str       = $self->as_str();

    # speculate public code: euc-jp -> iso-2022-jp.
    # we should ignore =?sjis? or =?euc? but use iso-2022-jp as output.
    use Mail::Message::Encode;
    use Mail::Message::Charset;
    my $encode  = new Mail::Message::Encode;
    my $charset = new Mail::Message::Charset;

    # XXX internal code to natural charset we should use in message header.
    # XXX So, if "=?sjis=..." is input, we return it as "=?iso-2022-jp...".
    my $code  = $encode->detect_code($str);                   # e.g. euc
    my $lang  = $charset->message_charset_to_language($code); # ja
    my $r     = $charset->language_to_message_charset($lang); # iso-2022-jp

    if ($r) {
	return $r;
    }
    else {
	my $hint_code = $self->{ _orig_mime_charset };
	return( $hint_code || '' );
    }
}


=head1 UTILITIES

=head2 unfold()

unfold in-core data.

=cut


# Descriptions: unfold in-core data.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _string }
# Return Value: STR
sub unfold
{
    my ($self) = @_;
    my $str    = $self->as_str();

    $str =~ s/\s*\n/ /g;
    $str =~ s/\s+/ /g;

    # save and return it.
    $self->set($str);
    return $str;
}


=head2 is_citation()

$data looks a citation or not.

=head2 is_signature()

$data looks a citation or not.

=cut


# Descriptions: looks a citation or not
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub is_citation
{
    my ($self)   = @_;
    my $data     = $self->as_str();
    my $trap_pat = ''; # keyword to trap citation at the head of the line.

    if ($data =~ /(\n.)/) { $trap_pat = quotemeta($1);}

    # XXX-TODO: only /\n>/ regexp is correct ?
    # > a i u e o ...
    # > ka ki ku ke ko ...
    if ($data =~ /\n>/) { return 1;}
    if ($trap_pat) { if ($data =~ /$trap_pat.*$trap_pat/) { return 1;}}

    return 0;
}


# Descriptions: looks a citation or not
#               XXX fml 4.0 assumes:
#               XXX If the paragraph has @ or ://, it must be signature.
#               trap special keyword like tel:011-123-456789 ...
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_signature
{
    my ($self) = @_;
    my $data   = $self->as_str();

    if ($data =~ /\@/o    ||
	$data =~ /TEL:/oi ||
	$data =~ /FAX:/oi ||
	$data =~ /:\/\//o ) {
	return 1;
    }

    # -- fukachan ( usenet style signature ? )
    # // fukachan ( signature derived from what ? )
    if ($data =~ /^--/o || $data =~ /^\/\//o) {
	return 1;
    }

    # XXX Japanese specific condition
    use Mail::Message::Encode;
    my $obj = new Mail::Message::Encode;
    $data   = $obj->convert( $data, 'euc-jp' );

    # "2-byte @"domain where "@" is a 2-byte "@" character.
    if ($data =~ /\241\367[-A-Za-z0-9]+|[-A-Za-z0-9]+\241\367/o) {
	return 1;
    }

    return 0;
}


#
# debug
#
if ($0 eq __FILE__) {
    $debug = 1;

    for my $_str ('=?ISO-2022-JP?B?GyRCJDckRCRiJHMbKEI=?=',
		  '=?ISO-2022-JP?B?GyRCJSshPCVJJS0lYyVXJT8hPCQ1JC8kaRsoQg==?=',
		  '=?SJIS?B?g0qBW4Nog0yDg4N2g16BW4Kzgq2C5w==?=',
		  'card captor sakura') {
	print "\nDATA: $_str\n";
	my $str  = new Mail::Message::String $_str;
	print "\tmime charset  = ", $str->get_mime_charset() ,"\n";
	print "\texternal code = ", $str->_speculate_external_charset(), "\n";
	print "\tinternal code = ", $str->_speculate_internal_code(), "\n";

	# decode
	$str->mime_decode();
	$str->charcode_convert();
	print " DECODED:", $str->as_str(), "\n";
	print "\tcurrent code = ", $str->get_charcode(), " (decoded)\n";

	# encode
	$str->mime_encode();
	print " ENCODED: ", $str->as_str(), "\n";
	print "ORIGINAL: ", $_str, "\n";
	print "\tcurrent code = ", $str->get_charcode(), " (encoded)\n";

	# decode
	$str->mime_decode();
	print "\tcurrent code = ", $str->get_charcode(), " (decoded again)\n";
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::String appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
