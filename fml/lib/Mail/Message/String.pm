#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: String.pm,v 1.3 2004/02/06 13:42:40 fukachan Exp $
#

package Mail::Message::String;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

Mail::Message::String - base class of string used in message (header).

=head1 SYNOPSIS

    package Mail::Message::Subject:
    use Mail::Message::String;
    @ISA = qw(Mail::Message::String);

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

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


# Descriptions: initialize data in this object.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: OBJ
sub set
{
    my ($self, $str)   = @_;
    $self->{ _string } = $str;
}


# Descriptions: get data in this object as string (same as as_str()).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub get
{
    my ($self) = @_;
    $self->as_str();
}


=head2 as_str()

return data (converted data) by string.

=cut


# Descriptions: return data (converted data) by string.
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


=head1 CHAR CODE CONVERSION UTILITIES

=head2 charcode_convert($out_code, [$in_code])

convert charactor code to $out_code and return it.

if $in_code is given, it is used as a hint.
if $in_code is not given, speculate the code.

if $out_code is not given, try to resolve the out code
based on the initial data (e.g. =?ISO-2022-JP? part).

=cut


# Descriptions: convert charactor code to $out_code and return it.
#               if $in_code is given, it is used as a hint.
#    Arguments: OBJ($self) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: none
sub charcode_convert
{
    my ($self, $out_code, $in_code) = @_;
    my $str       = $self->as_str();

    # speculate internal code we should use for this string.
    $out_code ||= $self->_speculate_internal_code();

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    $encode->convert_str_ref(\$str, $out_code, $in_code);
    $self->set($str);
    return $str;
}


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
    my $hint_code = $self->{ _orig_mime_charset };
    my $str       = $self->as_str();

    # speculate public code: euc-jp -> iso-2022-jp.
    if ($hint_code) {
	return $hint_code;
    }
    else {
	use Mail::Message::Encode;
	use Mail::Message::Charset;
	my $encode   = new Mail::Message::Encode;
	my $charset  = new Mail::Message::Charset;
	my $cur_code = $encode->detect_code($str);               # e.g. euc
	my $language = $charset->message_charset_to_language($cur_code); #ja
	return $charset->language_to_message_charset($language); # iso-2022-jp
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




#
# debug
#
if ($0 eq __FILE__) {
    my $_str = '=?ISO-2022-JP?B?GyRCJDckRCRiJHMbKEI=?=';
    my $str  = new Mail::Message::String $_str;
    print $str->get_mime_charset() ,"\n";
    $str->mime_decode();
    $str->charcode_convert();
    print $str->as_str(), "\t(CONVERTED TO ";
    print $str->get_charcode(), ")\n";
    $str->mime_encode();
    print $str->as_str(), "\n";
    print $_str, " (ORIGINAL)\n";
    print $str->get_charcode(), "\n";
    $str->mime_decode();
    print $str->get_charcode(), "\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::String appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
