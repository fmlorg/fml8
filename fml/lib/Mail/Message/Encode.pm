#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Encode.pm,v 1.1 2001/12/23 02:59:48 fukachan Exp $
#

package Mail::Message::Encode;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;


=head1 NAME

Mail::Message::Encode - handle a MIME encoded string

=head1 SYNOPSIS

    use Mail::Message::Encode qw(encode_mime_string);
    $encoded = encode_mime_string( $message );

=head1 DESCRIPTION

MIME utilities to encode the specified string $message.  It uses C<IM>
modlues as encoding engines.

=head1 METHODS

=cut


require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(encode_mime_string);


=head2 C<encode_mime_string(string, [$options])>

encode the C<string> by the encoder $options->{ encode }.
The encode is base64 by default.

C<options> is a HASH REFERENCE.
You can specify the charset of string to return
by $options->{ charset }.

=cut


# Descriptions: encode string
#    Arguments: STR($str) HASH_REF)$option)
# Side Effects: none
# Return Value: STR
sub encode_mime_string
{
    my ($str, $options) = @_;
    my $charset = $options->{ 'charset' } || 'iso-2022-jp';
    my $encode  = $options->{ 'encode' }  || 'base64';
    my $header  = '=?'. $charset;
    my $trailor = '?=';

    use Jcode;
    &Jcode::convert(\$str, 'jis');

    use IM::Iso2022jp;

    if ($encode eq 'base64') {
	line_iso2022jp_mimefy($str);
    }
    elsif ($encode eq 'qp') {
	$main::HdrQEncoding = 1;
	line_iso2022jp_mimefy($str);
	$main::HdrQEncoding = 0;
    }

    return $str;
}


=head1 SEE ALSO

L<Jcode>,
L<IM::Iso2022jp>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Encode appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
