#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: remove.pm,v 1.9 2002/09/11 23:18:10 fukachan Exp $
#

package FML::Command::User::remove;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::User::unsubscribe;
@ISA = qw(FML::Command::User::unsubscribe);


# Descriptions: unsubscribe user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to unsubscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::User::remove - unsubscribe

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

alias of C<FML::Command::User::unsubscribe>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::remove first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
