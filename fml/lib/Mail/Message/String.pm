#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: String.pm,v 1.1 2004/01/31 06:32:58 fukachan Exp $
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

    my $me = {};
    set($me, $str);
    $me->{ _orig_string } = $str;
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
    my $str = $self->{ _string };

    # base64 encoding by default.
    $encode ||= 'base64';

    use Mail::Message::Encode;
    my $obj = new Mail::Message::Encode;
    $str    = $obj->encode_mime_string($str, $encode, $out_code, $in_code);
    $self->{ _string } = $str;

    return $str;
}


# Descriptions: decode MIME string.
#    Arguments: OBJ($self) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub mime_decode
{
    my ($self, $out_code, $in_code) = @_;
    my $str = $self->{ _string };

    use Mail::Message::Encode;
    my $encode  = new Mail::Message::Encode;
    my $dec_string = $encode->decode_mime_string($str, $out_code, $in_code);
    $self->{ _string } = $dec_string;

    return $dec_string;
}


# Descriptions: dummy now. enforce charset to handle.
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
    my $str    = $self->{ _string };

    if ($str =~ /\=\?([-\w\d]+)\?/o) {
	my $charset = $1;
	$charset =~ tr/A-Z/a-z/;
	return $charset;
    }
    else {
	return '';
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
    my $str    = $self->{ _string };

    $str =~ s/\s*\n/ /g;
    $str =~ s/\s+/ /g;

    # save and return it.
    $self->{ _string } = $str;
    return $str;
}




#
# debug
#
if ($0 eq __FILE__) {
    my $str = '=?ISO-2022-JP?B?GyRCJDckRCRiJHMbKEI=?=';
    my $obj = new Mail::Message::String $str;
    print $obj->get_mime_charset() ,"\n";
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
