#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: PostfixControl.pm,v 1.3 2001/12/23 03:50:26 fukachan Exp $
#

package FML::MTAControl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::MTAControl - postfix utilities

=head1 SYNOPSIS

   nothing implemented yet.

=head1 DESCRIPTION

=head1 METHODS

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


# Descriptions: update alias
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub update_alias
{
    my ($self, $curproc, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type };

    if ($mta_type eq 'postfix') {
	$self->postfix_update_alias($curproc, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: update alias
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub postfix_update_alias
{
    my ($self, $curproc, $optargs) = @_;
    my $config = $curproc->{ config };
    my $prog   = $config->{ path_postalias };
    my $maps   = $optargs->{ alias_maps };

    for my $alias (@$maps) {
	system "$prog $alias";
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MTAControl appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
