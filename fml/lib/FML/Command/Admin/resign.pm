#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: resign.pm,v 1.11 2003/12/31 04:08:44 fukachan Exp $
#

package FML::Command::Admin::resign;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::unsubscribe;
@ISA = qw(FML::Command::Admin::unsubscribe);


# Descriptions: remove the specified user.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forward request to unsubscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    $self->SUPER::process($curproc, $command_context);
}

=head1 NAME

FML::Command::Admin::resign - remove the specified user

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

all requests are forwarded to C<FML::Command::Admin::unsubscribe>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::resign first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
