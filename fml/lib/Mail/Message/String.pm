#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.8 2004/01/01 07:29:27 fukachan Exp $
#

package Mail::Message::String;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

Mail::Message::String - what is this

=head1 SYNOPSIS

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
    my $me     = {
	_str      => $str,
	_orig_str => $str,
    };

    return bless $me, $type;
}


=head2 as_str()

return String by string.

=cut


# Descriptions: return String by string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub as_str
{
    my ($self) = @_;

    return( $self->{ _str } || '' );
}


=head1 MIME ENCODE/DECODE

=head2 mime_encode($encode, $out_code, $in_code)

=head2 mime_decode($out_code, $in_code)

=cut


# Descriptions: MIME encode of string.
#    Arguments: OBJ($self) STR($encode) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub mime_encode
{
    my ($self, $encode, $out_code, $in_code) = @_;
    my $str = $self->{ _str };

    # base64 encoding by default.
    $encode ||= 'base64';

    use Mail::Message::Encode;
    my $obj = new Mail::Message::Encode;
    $str    = $obj->encode_mime_string($str, $encode, $out_code, $in_code);
    $self->{ _str } = $str;

    return $str;
}


# Descriptions: decode MIME string.
#    Arguments: OBJ($self) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub mime_decode
{
    my ($self, $out_code, $in_code) = @_;
    my $str = $self->{ _str };

    use Mail::Message::Encode;
    my $encode  = new Mail::Message::Encode;
    my $dec_str = $encode->decode_mime_string($str, $out_code, $in_code);
    $self->{ _str } = $dec_str;

    return $dec_str;
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
