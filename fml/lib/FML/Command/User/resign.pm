#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: resign.pm,v 1.12 2003/12/31 03:49:18 fukachan Exp $
#

package FML::Command::User::resign;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::User::unsubscribe;
@ISA = qw(FML::Command::User::unsubscribe);


# Descriptions: unsubscribe request, forwarded to "unsubscribe" module.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to unsubscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::User::resign - unsubscribe request command

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Alias of C<FML::Command::User::unsubscribe>.
The unsubscribe request  is forwarded to C<FML::Command::User::unsubscribe>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::resign first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
