#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MIME.pm,v 1.15 2001/12/22 09:21:01 fukachan Exp $
#

package Mail::Message::Decode;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;


=head1 NAME

Mail::Message::Decode - handle a MIME encoded string

=head1 SYNOPSIS

    use Mail::Message::Decode qw(decode_mime_string encode_mime_string);
    $decoded = decode_mime_string( $message );

=head1 DESCRIPTION

MIME utilities to encode and decode string.
It uses C<MIME::Base64> and C<MIME::QuotedPrint> as encoding/decoding
engines.

=head1 METHODS

=cut


require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(decode_mime_string encode_mime_string);


=head2 C<decode_mime_string(string, [$options])>

decode a base64/quoted-printable encoded string to a plain message.
The encoding method is automatically detected.

C<$options> is a HASH REFERENCE.
You can specify the charset of the string to return
by $options->{ charset }.

=cut

sub decode_mime_string
{
    my ($str, $options) = @_;
    my $charset = $options->{ 'charset' } || 'euc-japan';

    if ($charset eq 'euc-japan') {
	use MIME::Base64;
	if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) {
	    $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
	}

	use MIME::QuotedPrint;
	if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) {
	    $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
	}
    }

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    $str;
}


=head1 SEE ALSO

L<Jcode>,
L<MIME::Base64>,
L<MIME::QuotedPrint>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Decode appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
