#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: moderatordel.pm,v 1.13 2003/12/31 03:49:16 fukachan Exp $
#

package FML::Command::Admin::moderatordel;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::delmoderator;
@ISA = qw(FML::Command::Admin::delmoderator);


# Descriptions: remove the specified remote moderatoristorator.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to delmoderator module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::Admin::moderatordel - remove the specified moderator

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

remove the specified moderatoristrator.

=head1 METHODS

=head2 process($curproc, $command_args)

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::moderatordel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
