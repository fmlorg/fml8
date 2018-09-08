#-*- perl -*-
#
#  Copyright (C) 2018 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package Mail::Message::Encode::Obsolete;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Message::Encode::Obsolete - obsolete encode/decode routines.

=head1 SYNOPSIS

=head1 DESCRIPTION

Temporarily obsolete functions in Mail::Message::Encode are moved to here.

=head1 MIME ENCODE/DECODE

=head2 encode_mime_string($str, $encode, $out_code, $in_code)

encode string $str to encoding system $encode with output code $out_code.
$in_code is used as a hint.

=cut


# Descriptions: encode string.
#    Arguments: OBJ($self) STR($str) STR($encode) STR($out_code) STR($in_code)
# Side Effects: croak() if language is unknown.
# Return Value: STR
sub encode_mime_string
{
    my ($self, $str, $encode, $out_code, $in_code) = @_;
    my $lang     = $self->{ _language };
    my $str_orig = $str;
    my $str_out  = '';

    # base64 encoding by default.
    $encode ||= 'base64';

    # code by default
    if ($lang eq 'japanese') {
	$out_code ||= 'jis';
	$str = $self->convert($str, $out_code, $in_code);
    }
    else {
	croak("Mail::Message::Encode: unknown language");
    }

    if ($encode eq 'base64') {
	eval q{
	    use IM::Iso2022jp;
	    $str_out = line_iso2022jp_mimefy($str);
	};
    }
    elsif ($encode eq 'qp') {
	eval q{
	    use IM::Iso2022jp;
	    $main::HdrQEncoding = 1;
	    $str_out = line_iso2022jp_mimefy($str);
	    $main::HdrQEncoding = 0;
	};
    }
    else {
	croak("Mail::Message::Encode: unknown encoding");
    }

    return $str_out ? $str_out : $str_orig;
}


=head2 decode_mime_string(string, [$options])

decode a base64/quoted-printable encoded string to a plain message.
The encoding method is automatically detected.

C<$options> is a HASH REFERENCE.
You can specify the charset of the string to return
by $options->{ charset }.

[reference] RFC1554 says:

      reg#  character set      ESC sequence                designated to
      ------------------------------------------------------------------
      6     ASCII              ESC 2/8 4/2      ESC ( B    G0
      42    JIS X 0208-1978    ESC 2/4 4/0      ESC $ @    G0
      87    JIS X 0208-1983    ESC 2/4 4/2      ESC $ B    G0
      14    JIS X 0201-Roman   ESC 2/8 4/10     ESC ( J    G0
      58    GB2312-1980        ESC 2/4 4/1      ESC $ A    G0
      149   KSC5601-1987       ESC 2/4 2/8 4/3  ESC $ ( C  G0
      159   JIS X 0212-1990    ESC 2/4 2/8 4/4  ESC $ ( D  G0
      100   ISO8859-1          ESC 2/14 4/1     ESC . A    G2
      126   ISO8859-7(Greek)   ESC 2/14 4/6     ESC . F    G2

=cut

# Descriptions: decode MIME string.
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: croak() if language is unknown.
# Return Value: STR
sub decode_mime_string
{
    my ($self, $str, $out_code, $in_code) = @_;
    my $lang    = $self->{ _language };
    my $str_out = '';

    unless ($str) { return $str;}

    if ($lang eq 'japanese') {
	if ($str =~ /=\?utf-8\?[bq]\?/i)  {
	    $str_out = $self->decode_mime_utf8_to_euc($str);
	}
	else {
	    eval q{
		use IM::EncDec;
		$str_out = mime_decode_string( $str );
	    };

	    return $str if $@;
	}
	# XXX IM returns "ESC$(B ... " string but
	# XXX mule 2.3 cannot read "ESC$(B ... ESC(B" string as JIS.
	# XXX ng detects it as ASCII.
	# XXX Whereas, w3m looks to be able to read it ?
	$str_out   =~ s/^\e\$\(B/\e\$B/; # make mule read this string.

	# XXX-TODO: use Mail::Message::Charset ?
	$in_code   = $self->detect_code($str_out);
	$out_code |= 'euc-jp'; # euc-jp by default.
    }
    else {
	croak("Mail::Message::Encode: unknown language");
    }

    return $self->convert($str_out, $out_code, $in_code);
}


# Descriptions: decode mime encoded string for utf8.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: STR
sub decode_mime_utf8_to_euc
{
    my ($self, $str) = @_;

    if ($str =~ /=\?utf-8\?(\w)\?/i) {
	if ($1 =~ /B/i) {
	    $str =~ s/=\?utf-8\?B\?([A-Za-z0-9+\/]+=*)\?=/$1/gi;
	    $str = $self->raw_decode_base64($str);
	}
	elsif ($1 =~ /Q/i)  {
	    $str =~ s/=\?utf-8\?q\?([\x20-\x7e\t]+?)\?=/$1/gi;
	    $str = $self->raw_decode_qp($str);
	}
    }

    $str =~ s/\n//g;
    use Jcode;
    return Jcode->new($str,"utf8")->euc;
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
