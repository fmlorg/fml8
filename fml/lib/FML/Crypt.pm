#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Crypt.pm,v 1.5 2004/01/02 16:08:37 fukachan Exp $
#

package FML::Crypt;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Crypt - raw level crypt library wrapper.

=head1 SYNOPSIS

    use FML::Crypt;
    my $crypt   = new FML::Crypt;
    my $p_input = $crypt->unix_crypt($text, $salt)

=head1 DESCRIPTION

FML::Crypt is an adapter layer for crypt libraries.
Now FML::Crypt is just a wrapper for Crypt::UnixCrypt module.

=head1 METHODS

=head2 new()

construcotor.

=cut


# Descriptions: construcotor.
#    Arguments: OBJ($self)
# Side Effects: one
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# XXX-TODO: hmm, strange object framework ?
# XXX-TODO: $str = FML::String; $str->unix_crypt(); ???


# Descriptions: raw level unix crypt(3) interface.
#    Arguments: OBJ($self) STR($text) STR($salt)
# Side Effects: none
# Return Value: STR
sub unix_crypt
{
    my ($self, $text, $salt) = @_;

    # always use this module's crypt
    use Crypt::UnixCrypt;
    return Crypt::UnixCrypt::crypt($text, $salt);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Crypt appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
