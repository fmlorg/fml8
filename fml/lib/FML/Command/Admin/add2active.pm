#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: add.pm,v 1.9 2004/01/02 14:42:42 fukachan Exp $
#

package FML::Command::Admin::add2active;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::addrecipient;
@ISA = qw(FML::Command::Admin::addrecipient);


# Descriptions: add user as only recipient
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to addrecipient module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::add - add a new recipient (recipient only)

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::addrecipient>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::add first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
