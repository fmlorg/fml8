#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.5 2002/01/18 15:37:38 fukachan Exp $
#

package FML::Encode;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Encode - encode/decode/charset conversion routines

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


# Descriptions: standard constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: load Encode or Jcode.
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    if ($] > 5.008) {
	eval q{ Encode;};
	croak("cannot load Encode") if $@;
    }
    elsif ($] <= 5.006001) {
	eval q{ use Jcode;};
	croak("cannot load Jcode") if $@;
    }

    # default language
    $me->{ _language } = 'japanese';

    return bless $me, $type;
}


# Descriptions: speculate code of $str
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: STR
sub detect_code
{
    my ($self, $str) = @_;
    my $lang = $self->{ _language };

    # code by default
    if ($lang eq 'japanese') {
	use Unicode::Japanese;
	my $obj = new Unicode::Japanese;
	$obj->getcode($str);
    }
    else {
	croak("FML::Encode: unknown language");
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


# Descriptions: convert $str to $out_code code
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub convert
{
    my ($self, $str, $out_code, $in_code) = @_;
    my $status = $self->convert_str_ref(\$str, $out_code, $in_code);
    return $str;
}


# Descriptions: convert string reference $str_str to $out_code code
#    Arguments: OBJ($self) STR_REF($str_ref) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: NUM(1/0)
sub convert_str_ref
{
    my ($self, $str_ref, $out_code, $in_code) = @_;
    my $lang = $self->{ _language };

    unless (ref($str_ref) eq 'SCALAR') {
	croak("convert_str_ref: invalid input data");
    }

    if ($lang eq 'japanese') {
	# 1. if the encoding for the given $str_ref is unknown, return ASAP.
	unless (defined $in_code) {
	    $in_code = $self->detect_code($$str_ref);
	    if ($in_code eq 'unknown') {
		return 0;
	    }
	}
	else {
	    print "1 ok\n";
	}

	# 2. try conversion ! (converted to 'euc' by default).
	if ($in_code) {
	    return $self->_jp_str_ref($str_ref, $out_code, $in_code);
	}	
    }
    else {
	croak("FML::Encode: unknown language");
    }

    return 0;
}


# Descriptions: convert japanese string to $out_code
#    Arguments: OBJ($self) STR_REF($str_ref) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: NUM(1/0)
sub _jp_str_ref
{
    my ($self, $str_ref, $out_code, $in_code) = @_;

    if ($out_code =~ /^(jis|sjis|euc)$|^(jis|sjis|euc)[-_]jp$/i) {
	my $code = $1 || $2;
	$code =~ tr/A-Z/a-z/;

	use Jcode;
	&Jcode::convert( $str_ref, $code, $in_code);

	return 1;
    }	
    elsif ($out_code =~ /^(iso2022jp|iso-2022-jp)$/i) {
	use Jcode;
	&Jcode::convert( $str_ref, 'jis', $in_code);

	return 1;
    }	

    return 0;
}


# Descriptions: run $proc($s) after $s is converted to $out_code code
#    Arguments: OBJ($self) CODE_REF($proc) STR($s) HASH_REF($args)
#               STR($out_code) STR($in_code) 
# Side Effects: none
# Return Value: none
sub run_in_code
{
    my ($self, $proc, $s, $args, $out_code, $in_code) = @_;
    my $proc_status = undef;

    my $obj         = new FML::Encode;
    my $conv_status = $obj->convert_str_ref($s, $out_code, $in_code);
    eval q{
	$proc_status = &$proc($s, $args);
    };

    if ($conv_status && $out_code) {
	$obj->convert_str_ref($s, $out_code, $in_code);
    }

    return wantarray ? ($conv_status, $proc_status): $conv_status;
}


=head1 BACKWARD COMPATIBILITY

=cut


# Descriptions: convert $str to euc
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2EUC
{
    my ($str) = @_;
    my $obj = new FML::Encode;
    $obj->convert( $str, 'euc-jp' );
}


# Descriptions: convert $str to sjis
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2SJIS
{
    my ($str) = @_;
    my $obj = new FML::Encode;
    $obj->convert( $str, 'sjis-jp' );
}


# Descriptions: convert $str to jis
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2JIS
{
    my ($str) = @_;
    my $obj = new FML::Encode;
    $obj->convert( $str, 'jis-jp' );
}


=head1 MIME ENCODE

=cut


# Descriptions: encode string
#    Arguments: OBJ($self) STR($str) STR($encode) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub encode_mime_string
{
    my ($self, $str, $encode, $out_code, $in_code) = @_;
    my $lang    = $self->{ _language };
    my $str_out = '';

    # base64 encoding by default.
    $encode ||= 'base64';

    # code by default
    if ($lang eq 'japanese') {
	$out_code ||= 'jis';

	use Jcode;
	&Jcode::convert(\$str, $out_code, $in_code);

    }
    else {
	croak("FML::Encode: unknown language");
    }

    use IM::Iso2022jp;
    if ($encode eq 'base64') {
        $str_out = line_iso2022jp_mimefy($str);
    }
    elsif ($encode eq 'qp') {
        $main::HdrQEncoding = 1;
        $str_out = line_iso2022jp_mimefy($str);
        $main::HdrQEncoding = 0;
    }
    else {
	croak("FML::Encode: unknown encoding");
    }

    return $str_out;
}


# Descriptions: encode $str by base64
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub base64
{
    my ($self, $str, $out_code, $in_code) = @_;
    $self->encode_mime_string($str, 'base64', $out_code, $in_code);
}


# Descriptions: encode $str by quoted-printable
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub qp
{
    my ($self, $str, $out_code, $in_code) = @_;
    $self->encode_mime_string($str, 'qp', $out_code, $in_code);
}


if ($0 eq __FILE__) {
    $| = 1; 

    my $obj = new FML::Encode;
    my $str = 'ほえ〜 といえばさくらちゃんですぅ 1234 １２３４';
    my $str0;

    print "=> test string\n";
    print $str, "\n";

    print "\n=> base64\n";
    print $obj->base64($str), "\n";

    print "\n=> quoted printable\n";
    print $obj->qp($str), "\n";

    print "\n=> str code is <";
    print $obj->detect_code($str), ">\n";

    for my $code (qw(jis sjis euc)) {
	print "\n=> convert_str_ref($code)   \tresult is <";
	$obj->convert_str_ref(\$str, $code);
	print $obj->detect_code($str), ">/";

	{
	    use Jcode;
	    my ($c) = &Jcode::getcode( $str );
	    print "<$c>\n";
	}
    }

    $str0 = STR2EUC( $str );
    print "\n=> STR2EUC  ? = <", $obj->detect_code($str0), ">\n";

    $str0 = STR2SJIS( $str );
    print "\n=> STR2SJIS ? = <", $obj->detect_code($str0), ">\n";

    $str0 = STR2JIS( $str );
    print "\n=> STR2JIS  ? = <", $obj->detect_code($str0), ">\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Encode appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
