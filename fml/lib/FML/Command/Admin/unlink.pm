#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ls.pm,v 1.1 2002/03/24 11:26:46 fukachan Exp $
#

package FML::Command::Admin::ls;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::delete;
@ISA = qw(FML::Command::Admin::delete);


# Descriptions: delete files
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to delete module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::unlink - remove file

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

same as C<delete>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::ls appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
