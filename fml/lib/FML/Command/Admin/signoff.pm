#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: signoff.pm,v 1.3 2001/12/22 09:21:04 fukachan Exp $
#

package FML::Command::Admin::signoff;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Utils;
use FML::Command::Admin::unsubscribe;
@ISA = qw(FML::Command::Admin::unsubscribe use FML::Command::Utils);


# Descriptions: unsubscribe user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to unsubscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::unsubscribe($curproc, $command_args);
}


=head1 NAME

FML::Command::Admin::signoff - signoff the specified member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

all requests are forwarded to C<FML::Command::Admin::unsubscribe>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::signoff appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
