#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: byepriv.pm,v 1.2 2002/04/03 11:32:59 fukachan Exp $
#

package FML::Command::Admin::byepriv;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::byeadmin;
@ISA = qw(FML::Command::Admin::byeadmin);


# Descriptions: remove the specified administrator
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to byeadmin module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::bye - remove the specified administrator

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::byeadmin>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::bye first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
