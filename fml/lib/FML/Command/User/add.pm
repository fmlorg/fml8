#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: add.pm,v 1.9 2002/09/22 14:56:47 fukachan Exp $
#

package FML::Command::User::add;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::User::subscribe;
@ISA = qw(FML::Command::User::subscribe);


# Descriptions: subscribe request, which forwarded to subscribe module.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to subscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::User::add - subscribe request command

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

forward request to C<FML::Command::User::subscribe> module.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::add first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
