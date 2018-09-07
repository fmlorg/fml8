#-*- perl -*-
#
#  Copyright (C) 2018 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package Mail::Message::Encode::Perl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Encode;
use Encode::MIME::Header;

=head1 NAME

Mail::Message::Encode::Perl - Perl (character-oriented) based Encoding

=head1 SYNOPSIS

    use Mail::Message::Encode::Perl;
    my $obj = new Mail::Message::Encode::Perl;

    my $pif_str = $obj->mime_header_decode($str);
    # ("[BSG:75] Re: Exodus Part II", "UTF-8", "base64")

    # ... several works ... 
    $pif_str  =~ s/Re: //;
    Mail::Message::Subject->rewrite_XXX($pif_str);

    $mime_str = $obj->mime_header_encode($pif_str);
    print $mime_str;

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 guess_encoding($str)

speculate the encoding of $str string. $str is checked by
Unicode::Japanese. Unicode::Japanes::getcode() can detect the following
code: jis, sjis, euc, utf8, ucs2, ucs4, utf16, utf16-ge, utf16-le,
utf32, utf32-ge, utf32-le, ascii, binary, sjis-imode, sjis-doti,
sjis-jsky.

C<CAUTION>: Hmm, we suppose we handle only Japanese and English here...

=cut


# Descriptions: speculate code of $str string.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: STR
sub guess_encoding
{
    my ($self, $str) = @_;

    use Unicode::Japanese;
    my $obj = new Unicode::Japanese;
    return $obj->getcode($str);
}


=head2 mime_header_enecode($str)

encode the given Perl internal format string to the mime header one.

=head2 mime_header_decode($str)

decode the given mime header format string to the Perl internal one.

=head3 CAUTION

In the current Perl (for backward compatibility), 
we need to handle the string this way.

   IN -> decode() -> Perl Internal UTF8 format -> encode() -> OUT

=cut

# Descriptions: encode the Perl internal format string to the mime header one.
#    Arguments: OBJ($self) STR($pif_str)
# Side Effects: none
# Return Value: STR
sub mime_header_encode
{
    my ($self, $pif_str) = @_;
    my $m;

    # XXX how we specify the encoding ?
    if (1) { # base64 by default
        $m = encode("MIME-Header", $pif_str, Encode::FB_WARN);
    }
    else {
        $m = encode("MIME-Q", $pif_str, Encode::FB_WARN);
    }
    return $m;
}

# Descriptions: decode mime header format string to the Perl internal one.
#    Arguments: OBJ($self) STR($pef_str)
# Side Effects: none
# Return Value: STR(perl internal UTF8 format)
sub mime_header_decode
{
    my ($self, $pef_str) = @_;

    decode("MIME-Header", $pef_str);
}


# Descriptions: decode mime header format string and return it as 
#               printable format not the Perl internal one.
#    Arguments: OBJ($self) STR($pef_str)
# Side Effects: none
# Return Value: STR
sub mime_header_decode_as_octets
{
    my ($self, $pef_str) = @_;

    # XXX-TODO hard-coded now anyway.
    my $code = "EUC-JP";
    encode($code, decode("MIME-Header", $pef_str));
}


=head2 convert_from_internal_to_external_form($pif_str)

convert the given Perl internal form to the external printable one.

=cut


# Descriptions: convert the given Perl internal form 
#               to the external printable one.
#    Arguments: OBJ($self) STR($pif_str)
# Side Effects: none
# Return Value: STR
sub convert_from_internal_to_external_form
{
    my ($self, $pif_str) = @_;

    # XXX-TODO hard-coded now anyway.
    my $code = "EUC-JP";
    utf8::is_utf8($pif_str) ? encode($code, $pif_str) : $pif_str;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2018 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Encode first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
