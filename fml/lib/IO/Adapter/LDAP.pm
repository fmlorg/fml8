#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: LDAP.pm,v 1.10 2001/12/22 09:21:13 fukachan Exp $
#

package IO::Adapter::LDAP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


#####                               #####
##### This is just a dummy yet now. #####
#####                               #####


=head1 NAME

IO::Adapter::LDAP - IO by LDAP

=head1 SYNOPSIS

not yet implemented

=head1 DESCRIPTION

not yet

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::LDAP appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
