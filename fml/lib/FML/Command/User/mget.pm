#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: mget.pm,v 1.12 2002/12/15 13:46:30 fukachan Exp $
#

package FML::Command::User::mget;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::User::get;
@ISA = qw(FML::Command::User::get);


# Descriptions: send back article(s).
#               The request is forwarded to "get" module.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to get module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::User::mget - send back article(s)

=head1 SYNOPSIS

forwarded C<FML::Command::User::get>.

=head1 DESCRIPTION

This module sends back article(s).
An alias of C<FML::Command::User::get>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::mget first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
