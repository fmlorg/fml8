#-*- perl -*-
#
#  Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: moderatordel.pm,v 1.1 2004/05/02 00:56:49 fukachan Exp $
#

package FML::Command::Admin::moderatordel;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::delmoderator;
@ISA = qw(FML::Command::Admin::delmoderator);


# Descriptions: remove the specified remote moderatoristorator.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forward request to delmoderator module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    $self->SUPER::process($curproc, $command_context);
}


=head1 NAME

FML::Command::Admin::moderatordel - remove the specified moderator

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

remove the specified moderatoristrator.

=head1 METHODS

=head2 process($curproc, $command_context)

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::moderatordel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
