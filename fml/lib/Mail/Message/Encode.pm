#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2011 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Encode.pm,v 1.24 2011/08/25 00:39:58 fukachan Exp $
#

package Mail::Message::Encode;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Message::Encode - encode/decode/charset conversion routines.

=head1 SYNOPSIS

    use Mail::Message::Encode;
    my $code = Mail::Message::Encode->detect_code($str);

It is not recommended but if you use old style, import required function:

    use Mail::Message::Encode qw(STR2EUC);
    my $euc_string = STR2EUC($string);


=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: load Encode or Jcode.
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # XXX we do not use Encode yet, so disabled anyway.
    if (0 && $] > 5.008) {
	eval q{ use Encode;};
	croak("cannot load Encode") if $@;
    }
    elsif (1 && $] <= 5.006001) {
	eval q{ use Jcode;};
	croak("cannot load Jcode") if $@;
    }

    # default language
    # XXX 'japanese' includes both Japanese and English.
    $me->{ _language } = 'japanese';

    return bless $me, $type;
}


=head2 detect_code($str)

speculate the code of $str string. $str is checked by
Unicode::Japanese. Unicode::Japanes::getcode() can detect the follogin
code: jis, sjis, euc, utf8, ucs2, ucs4, utf16, utf16-ge, utf16-le,
utf32, utf32-ge, utf32-le, ascii, binary, sjis-imode, sjis-doti,
sjis-jsky.

C<CAUTION>: we handle only Japanese and English.

=cut


# Descriptions: speculate code of $str string.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: STR
sub detect_code
{
    my ($self, $str) = @_;
    my $lang = $self->{ _language };

    # XXX Japanese includes English.
    if ($lang eq 'japanese' || $lang eq 'english') {
	# getcode() can detect the follogin code:
	# jis, sjis, euc, utf8, ucs2, ucs4, utf16, utf16-ge, utf16-le,
	# utf32, utf32-ge, utf32-le, ascii, binary, sjis-imode,
	# sjis-doti, sjis-jsky.
	use Unicode::Japanese;
	my $obj = new Unicode::Japanese;
	return $obj->getcode($str);
    }
    else {
	carp("Mail::Message::Encode: unknown language");
	return 'unknown';
    }
}


# Unicode::Japanese
#           'jis', 'sjis', 'euc', 'utf8', 'ucs2', 'ucs4', 'utf16',
#           'utf16-ge', 'utf16-le', 'utf32', 'utf32-ge',
#           'utf32-le', 'ascii', 'binary', 'sjis-imode', 'sjis-
#           doti', 'sjis-jsky'.
#
# Jcode
#            ascii   Ascii (Contains no Japanese Code)
#            binary  Binary (Not Text File)
#            euc     EUC-JP
#            sjis    SHIFT_JIS
#            jis     JIS (ISO-2022-JP)
#            ucs2    UCS2 (Raw Unicode)
#            utf8    UTF8


=head2 convert($str, $out_code, $in_code)

convert $str to $out_code code.
$in_code is used as a hint.

=head2 convert_str_ref($str_ref, $out_code, $in_code)

convert string reference $str_str to $out_code code.
$in_code is used as a hint.

=cut


# Descriptions: convert $str to $out_code code.
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub convert
{
    my ($self, $str, $out_code, $in_code) = @_;
    my $status = $self->convert_str_ref(\$str, $out_code, $in_code);
    return $str;
}


# Descriptions: convert string reference $str_str to $out_code code.
#    Arguments: OBJ($self) STR_REF($str_ref) STR($out_code) STR($in_code)
# Side Effects: croak() if input data is invalid.
# Return Value: NUM(1/0)
sub convert_str_ref
{
    my ($self, $str_ref, $out_code, $in_code) = @_;
    my $lang = $self->{ _language };

    unless (ref($str_ref) eq 'SCALAR') {
	croak("convert_str_ref: invalid input data");
    }

    # XXX Japanese includes English.
    if ($lang eq 'japanese' || $lang eq 'english') {
	# 1. if the encoding for the given $str_ref is unknown, return ASAP.
	unless (defined $in_code) {
	    $in_code = $self->detect_code($$str_ref);
	    if ($in_code eq 'unknown') {
		return 0;
	    }
	}
	else {
	    # print "1 ok\n";
	}

	# 2. try conversion ! (converted to 'euc' by default).
	if ($in_code) {
	    return $self->_jp_str_ref($str_ref, $out_code, $in_code);
	}
    }
    else {
	croak("Mail::Message::Encode: unknown language");
    }

    return 0;
}


# Descriptions: convert japanese string to $out_code.
#               XXX $in_code must be determined here !
#    Arguments: OBJ($self) STR_REF($str_ref) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: NUM(1/0)
sub _jp_str_ref
{
    my ($self, $str_ref, $out_code, $in_code) = @_;

    if ($out_code =~ /^(jis|sjis|euc)$|^(jis|sjis|euc)[-_]jp$/i) {
	my $code = $1 || $2;
	$code    =~ tr/A-Z/a-z/;

	use Jcode;
	&Jcode::convert($str_ref, $code, $in_code);

	return 1;
    }
    elsif ($out_code =~ /^(iso2022jp|iso-2022-jp)$/i) {
	use Jcode;
	&Jcode::convert($str_ref, 'jis', $in_code);

	return 1;
    }

    return 0;
}


=head2 run_in_code($proc, $s, $args, $out_code, $in_code)

run $proc($s) under $out_code environment.
So, execute $proc like this.

    my $obj         = new Mail::Message::Encode;
    my $conv_status = $obj->convert_str_ref($s, $out_code, $in_code);

    &$proc($s, $args);

It means run $proc() after $s is converted to $out_code code.

=cut


# Descriptions: run $proc($s) under $out_code environment.
#               It means run $proc() after $s is converted to $out_code code.
#    Arguments: OBJ($self) CODE_REF($proc) STR($s) HASH_REF($args)
#               STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: none
sub run_in_code
{
    my ($self, $proc, $s, $args, $out_code, $in_code) = @_;
    my $proc_status = undef;

    my $obj         = new Mail::Message::Encode;
    my $conv_status = $obj->convert_str_ref(\$s, $out_code, $in_code);

    # XXX-TODO: validate $proc name regexp.
    eval q{
	$proc_status = &$proc($s, $args);
    };

    # XXX-TODO: correct ?
    if ($conv_status && $out_code) {
	$obj->convert_str_ref($s, $out_code, $in_code);
    }

    return wantarray ? ($conv_status, $proc_status): $conv_status;
}


=head1 UTILITIES

=head2 is_iso2022jp_string($buf)

$buf looks like Japanese or not ?

=cut


# Descriptions: $buf looks like Japanese or not ?
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_iso2022jp_string
{
    my ($self, $buf) = @_;
    return (not _look_not_iso2022jp_string($buf));
}


# Descriptions: $buf looks like Japanese or not ?
#               based on fml-support: 07020, 07029
#                  Koji Sudo <koji@cherry.or.jp>
#                  Takahiro Kambe <taca@sky.yamashina.kyoto.jp>
#               check the given buffer has unusual Japanese (not ISO-2022-JP)
#    Arguments: STR($buf)
#      History: imported fml 4.0 functions.
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _look_not_iso2022jp_string
{
    my ($buf) = @_;

    # trivial check;
    return 0 unless defined $buf;
    return 0 unless $buf;

    # check 8 bit on
    if ($buf =~ /[\x80-\xFF]/){
        return 1;
    }

    # check SI/SO
    if ($buf =~ /[\016\017]/) {
        return 1;
    }

    # HANKAKU KANA
    if ($buf =~ /\033\(I/) {
        return 1;
    }

    # MSB flag or other control sequences
    if ($buf =~ /[\001-\007\013\015\020-\032\034-\037\177-\377]/) {
        return 1;
    }

    0; # O.K.
}


=head1 BACKWARD COMPATIBILITY

=head2 STR2EUC($str)

convert $str to japanese EUC code.

=head2 STR2JIS($str)

convert $str to japanese JIS code.

=head2 STR2SJIS($str)

convert $str to japanese SJIS code.

=cut


# Descriptions: convert $str to euc.
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2EUC
{
    my ($str) = @_;
    my $obj = new Mail::Message::Encode;
    $obj->convert( $str, 'euc-jp' );
}


# Descriptions: convert $str to sjis.
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2SJIS
{
    my ($str) = @_;
    my $obj = new Mail::Message::Encode;
    $obj->convert( $str, 'sjis-jp' );
}


# Descriptions: convert $str to jis.
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2JIS
{
    my ($str) = @_;
    my $obj = new Mail::Message::Encode;
    $obj->convert( $str, 'jis-jp' );
}


=head1 MIME ENCODE/DECODE

=cut


# Descriptions: decode MIME base64 encoded-string.
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: croak() if language is unknown.
# Return Value: STR
sub decode_base64_string
{
    my ($self, $str, $out_code, $in_code) = @_;
    my $lang    = $self->{ _language };
    my $str_out = undef;

    if ($lang eq 'japanese') {
	eval q{
	    use MIME::Base64::Perl;
	    $str_out = decode_base64( $str );
	};

	return $str if $@;

	# XXX-TODO: use Mail::Message::Charset ?
	$in_code   = $self->detect_code($str_out);
	$out_code |= 'euc-jp'; # euc-jp by default.
    }
    else {
	croak("Mail::Message::Encode: unknown language");
    }

    return $self->convert($str_out, $out_code, $in_code);
}


# Descriptions: decode MIME quoted-printable encoded-string.
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: croak() if language is unknown.
# Return Value: STR
sub decode_qp_string
{
    my ($self, $str, $out_code, $in_code) = @_;
    my $lang    = $self->{ _language };
    my $str_out = undef;

    if ($lang eq 'japanese') {
	eval q{
	    use MIME::QuotedPrint::Perl;
	    $str_out = decode_qp( $str );
	};
	return $str if $@;

	# XXX-TODO: use Mail::Message::Charset ?
	$in_code   = $self->detect_code($str_out);
	$out_code |= 'euc-jp'; # euc-jp by default.
    }
    else {
	croak("Mail::Message::Encode: unknown language");
    }

    return $self->convert($str_out, $out_code, $in_code);
}


# Descriptions: decode mime encoded string.
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: STR
sub raw_decode_base64
{
    my ($self, $buf) = @_;
    my $rbuf = '';

    eval q{
	use MIME::Base64::Perl;
	$rbuf = decode_base64($buf);
    };

    return( $rbuf || $buf );
}


# Descriptions: decode mime encoded string.
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: STR
sub raw_decode_qp
{
    my ($self, $buf) = @_;
    my $rbuf = '';

    eval q{
	use MIME::QuotedPrint::Perl;
	$rbuf = decode_qp($buf);
    };

    return( $rbuf || $buf );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2011 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Encode first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
